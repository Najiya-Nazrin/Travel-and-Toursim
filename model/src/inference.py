# inference.py
"""
Inference pipeline:
- Loads precomputed artifacts (embeddings, index, KG, item map)
- Exposes recommend_trip(input_json) -> dict
- Uses weighted combination of:
    content similarity, KG proximity, CF/popularity fallback
- Returns: recommended_spots, hotels, food, cultural_events

Usage:
    python inference.py --source "Kozhikode" --destination "Kochi" \
        --start_date "20 Oct 2025" --end_date "25 Oct 2025" --diet "Non-Veg"
"""

import os
import json
import pickle
import argparse
import numpy as np
import hnswlib
import networkx as nx
from sentence_transformers import SentenceTransformer
from datetime import datetime

# === Paths ===
ROOT = os.path.join(os.path.dirname(__file__), "..")
ART_DIR = os.path.join(ROOT, "artifacts")
DATA_DIR = os.path.join(ROOT, "data")

# Artifacts
CONTENT_EMB = os.path.join(ART_DIR, "content_embeddings.npy")
NODE2VEC_EMB = os.path.join(ART_DIR, "node2vec_embeddings.npy")
ITEM_FACTORS = os.path.join(ART_DIR, "item_factors.npy")
ITEM_MAP = os.path.join(ART_DIR, "item_map.json")
HNSW_INDEX = os.path.join(ART_DIR, "item_index_hnsw.bin")
KG_FILE = os.path.join(ART_DIR, "kg_graph.pkl")

# === Weights ===
W_CONTENT = 0.5
W_KG = 0.3
W_CF = 0.2

SENTENCE_MODEL = "all-MiniLM-L6-v2"

# === Load Artifacts ===
print("Loading artifacts...")

with open(ITEM_MAP, "r", encoding="utf-8") as f:
    item_map = json.load(f)
n_items = len(item_map)

content_emb = np.load(CONTENT_EMB)
node2vec_emb = np.load(NODE2VEC_EMB)
item_factors = np.load(ITEM_FACTORS)

# Normalize embeddings
def l2_normalize(x):
    return x / np.maximum(np.linalg.norm(x, axis=1, keepdims=True), 1e-12)

content_emb = l2_normalize(content_emb)
node2vec_emb = l2_normalize(node2vec_emb)
item_factors = l2_normalize(item_factors)

combined_emb = np.concatenate([content_emb, node2vec_emb, item_factors], axis=1)
combined_emb = l2_normalize(combined_emb)

# Load HNSW index
dim = combined_emb.shape[1]
index = hnswlib.Index(space='cosine', dim=dim)
index.load_index(HNSW_INDEX)
print(f"Loaded HNSW index with {n_items} items.")

# Load KG
with open(KG_FILE, "rb") as f:
    KG = pickle.load(f)
print(f"Loaded KG: {KG.number_of_nodes()} nodes, {KG.number_of_edges()} edges")

# Load text encoder
text_model = SentenceTransformer(SENTENCE_MODEL)

# --- Utility ---
def get_node_id_for_city(city_name):
    nid = f"city:{city_name}"
    if nid in KG.nodes:
        return nid
    # fallback fuzzy match
    for n in KG.nodes:
        if city_name.lower() in str(n).lower():
            return n
    return None

def compute_kg_proximity_scores(destination_city, qids):
    """Compute proximity (1 / (shortest path length + 1)) for items from destination."""
    dest_node = get_node_id_for_city(destination_city)
    if dest_node is None:
        return np.zeros(len(qids))
    scores = np.zeros(len(qids))
    for i, qid in enumerate(qids):
        if not KG.has_node(qid):
            continue
        try:
            d = nx.shortest_path_length(KG, source=qid, target=dest_node)
            scores[i] = 1.0 / (d + 1.0)
        except (nx.NetworkXNoPath, nx.NodeNotFound):
            scores[i] = 0.0
    return scores

def compute_content_similarity(input_json):
    """Encode text description of travel plan and get content similarity."""
    text = f"Trip from {input_json['source']} to {input_json['destination']} " \
           f"between {input_json['start_date']} and {input_json['end_date']}. " \
           f"Diet preference: {input_json.get('veg/non-veg','Any')}."
    q_emb = text_model.encode([text], normalize_embeddings=True)
    q_emb = np.array(q_emb, dtype=np.float32)

    # Pad with zeros for node2vec + CF dimensions
    total_dim = combined_emb.shape[1]
    content_dim = content_emb.shape[1]
    if q_emb.shape[1] < total_dim:
        pad = np.zeros((1, total_dim - content_dim), dtype=np.float32)
        q_emb = np.concatenate([q_emb, pad], axis=1)

    # Safety check
    assert q_emb.shape[1] == total_dim, f"Query dim {q_emb.shape[1]} != index dim {total_dim}"

    labels, distances = index.knn_query(q_emb, k=50)
    labels = labels[0]
    distances = 1 - distances[0]  # cosine similarity
    return labels, distances

def filter_events_by_date(events, start_date, end_date):
    def parse_date(d):
        try:
            return datetime.strptime(d, "%d %b %Y")
        except:
            return None

    start = parse_date(start_date)
    end = parse_date(end_date)
    if not start or not end:
        return events

    filtered = []
    for e in events:
        meta = e.get("meta", {})
        estart = parse_date(meta.get("start"))
        eend = parse_date(meta.get("end"))
        if estart and eend and (estart <= end and eend >= start):
            filtered.append(e)
    return filtered
    
def recommend_trip(input_json):
    """Main hybrid recommendation function."""
    print(f"Running recommendation for: {input_json}")

    qids = [item_map[str(i)]["qid"] for i in range(n_items)]
    labels, sim_scores = compute_content_similarity(input_json)

    # Subset of candidates (top 200 by content)
    candidate_idx = labels[:] #labels[:200]
    candidate_qids = [item_map[str(i)]["qid"] for i in candidate_idx]

    # KG proximity
    kg_scores = compute_kg_proximity_scores(input_json["destination"], candidate_qids)

    # CF popularity (simple: norm of item_factors)
    cf_scores = 0 #np.linalg.norm(item_factors[candidate_idx], axis=1)

    # Weighted hybrid score
    final_scores = (
        W_CONTENT * sim_scores[:len(candidate_idx)]
        + W_KG * kg_scores
        + W_CF * cf_scores
    )

    # Compose structured results
    results = []
    for i, idx in enumerate(candidate_idx):
        info = item_map[str(idx)]
        info["priority_score"] = float(final_scores[i])
        results.append(info)

    # Split by type
    spots = [r for r in results if (r["type"] == "place") and ("hotel" not in str(r["meta"].get("type", "")).lower())]
    hotels = [r for r in results if "hotel" in str(r["meta"].get("type", "")).lower()]
    foods = [r for r in results if r["type"] == "food"]
    events = [r for r in results if r["type"] == "event"]
    events = filter_events_by_date(events, input_json["start_date"], input_json["end_date"])


    def dedup_by_label(lst):
        seen = set()
        deduped = []
        for item in lst:
            key = item["label"].strip().lower()
            if key not in seen:
                seen.add(key)
                deduped.append(item)
        return deduped

    def topk(lst, k): 
        lst = dedup_by_label(lst)
        return sorted(lst, key=lambda x: x["priority_score"], reverse=True)[:k]

    output = {
        "recommended_spots": topk(spots, 10),
        "hotels": topk(hotels, 5),
        "food": topk(foods, 10),
        "cultural_events": topk(events, 5)
    }

    return output

# === CLI Runner ===
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run trip recommendation")
    parser.add_argument("--source", type=str, required=True)
    parser.add_argument("--destination", type=str, required=True)
    parser.add_argument("--start_date", type=str, required=True)
    parser.add_argument("--end_date", type=str, required=True)
    parser.add_argument("--diet", type=str, default="Any", help="Veg or Non-Veg")

    args = parser.parse_args()
    input_json = {
        "source": args.source,
        "destination": args.destination,
        "start_date": args.start_date,
        "end_date": args.end_date,
        "veg/non-veg": args.diet
    }

    output = recommend_trip(input_json)

    print("\n=== Recommended Trip Plan ===")
    for k, v in output.items():
        print(f"\n{k.upper()}:")
        for item in v:
            print(f" - {item['label']} ({item['qid']}) [score={item['priority_score']:.3f}]")
