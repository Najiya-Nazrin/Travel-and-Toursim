# train.py
"""
Train pipeline:
1) Load items/events/food and KG
2) Compute content embeddings (sentence-transformers)
3) Compute KG embeddings (Node2Vec)
4) Compute collaborative-style item factors (synthetic interactions + SVD)
5) Build combined item vectors and save all artifacts:
   - artifacts/content_embeddings.npy
   - artifacts/node2vec_embeddings.npy
   - artifacts/item_factors.npy
   - artifacts/item_index_hnsw.bin
   - artifacts/item_map.json
"""

import os
import json
import csv
import pickle
import random
from collections import Counter, defaultdict

import numpy as np
import hnswlib
import networkx as nx
from tqdm import tqdm

# --- Optional libs that may need pip install ---
# sentence-transformers, node2vec, scikit-learn
try:
    from sentence_transformers import SentenceTransformer
except Exception as e:
    raise ImportError(
        "sentence-transformers not found. Install with: pip install sentence-transformers"
    )

try:
    from node2vec import Node2Vec
except Exception as e:
    raise ImportError(
        "node2vec not found. Install with: pip install node2vec"
    )

from sklearn.decomposition import TruncatedSVD
from scipy.sparse import csr_matrix

# === Paths ===
ROOT = os.path.join(os.path.dirname(__file__), "..")
DATA_DIR = os.path.join(ROOT, "data")
ART_DIR = os.path.join(ROOT, "artifacts")
os.makedirs(ART_DIR, exist_ok=True)

ITEMS_CSV = os.path.join(DATA_DIR, "items.csv")
EVENTS_CSV = os.path.join(DATA_DIR, "events.csv")
FOOD_CSV = os.path.join(DATA_DIR, "food.csv")
KG_IN = os.path.join(ART_DIR, "kg_graph.pkl")

CONTENT_EMB_OUT = os.path.join(ART_DIR, "content_embeddings.npy")
NODE2VEC_EMB_OUT = os.path.join(ART_DIR, "node2vec_embeddings.npy")
ITEM_FACTORS_OUT = os.path.join(ART_DIR, "item_factors.npy")
HNSW_OUT = os.path.join(ART_DIR, "item_index_hnsw.bin")
ITEM_MAP_OUT = os.path.join(ART_DIR, "item_map.json")

# --- Configs ---
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

SENTENCE_MODEL = "all-MiniLM-L6-v2"  # compact and fast
NODE2VEC_DIM = 128
CONTENT_DIM = 384  # all-MiniLM-L6-v2 produces 384-d
CF_DIM = 64
FINAL_DIM = None  # computed later (content + node2vec + cf)

# HNSW params
HNSW_SPACE = "cosine"  # nearest neighbors by cosine similarity
HNSW_M = 32
HNSW_EF_CONSTRUCTION = 200
HNSW_EF_SEARCH = 50

# Synthetic CF params
NUM_SYN_USERS = 1200
MIN_ITEMS_PER_USER = 5
MAX_ITEMS_PER_USER = 25

# --- Utilities ---
def safe_label(s):
    return (s or "").strip()

def load_items():
    items = []
    if not os.path.exists(ITEMS_CSV):
        print(f"[warn] {ITEMS_CSV} not found.")
        return items
    with open(ITEMS_CSV, newline='', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for r in reader:
            name = safe_label(r.get("Name"))
            city = safe_label(r.get("City"))
            type_ = safe_label(r.get("Type")).lower()
            desc = safe_label(r.get("Description"))
            lat = r.get("Latitude")
            lon = r.get("Longitude")
            qid = f"place:{name}"
            items.append({
                "qid": qid,
                "label": name,
                "type": "place",
                "city": city,
                "meta": {"type": type_, "lat": lat, "lon": lon, "description": desc}
            })
    return items

def load_events():
    events = []
    if not os.path.exists(EVENTS_CSV):
        print(f"[warn] {EVENTS_CSV} not found.")
        return events
    with open(EVENTS_CSV, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            name = safe_label(r.get("Festival Name"))
            city = safe_label(r.get("City"))
            loc = safe_label(r.get("Location"))
            start = safe_label(r.get("Start Date"))
            end = safe_label(r.get("End Date"))
            if not name:
                continue
            qid = f"event:{name}"
            label = name
            desc = f"Event in {city}. Location: {loc}. Dates: {start} - {end}"
            events.append({
                "qid": qid,
                "label": label,
                "type": "event",
                "city": city,
                "meta": {"location": loc, "start": start, "end": end, "description": desc}
            })
    return events

def load_foods():
    foods = []
    if not os.path.exists(FOOD_CSV):
        print(f"[warn] {FOOD_CSV} not found.")
        return foods
    with open(FOOD_CSV, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            name = safe_label(r.get("Name"))
            cuisine = safe_label(r.get("Cuisine"))
            desc = safe_label(r.get("Description"))
            diet = safe_label(r.get("Diet"))
            city = safe_label(r.get("City") or r.get("Cuisine"))  # fallback if CSV inconsistent
            if not name:
                continue
            qid = f"food:{name}"
            label = name
            foods.append({
                "qid": qid,
                "label": label,
                "type": "food",
                "city": city,
                "meta": {"cuisine": cuisine, "diet": diet, "description": desc}
            })
    return foods

def unify_items():
    # returns list of items and a map qid->index
    places = load_items()
    events = load_events()
    foods = load_foods()
    items = places + events + foods
    qid_to_idx = {it["qid"]: idx for idx, it in enumerate(items)}
    print(f"Loaded items: {len(items)} (places: {len(places)}, events: {len(events)}, foods: {len(foods)})")
    return items, qid_to_idx

# --- Embedding steps ---
def compute_content_embeddings(items, model_name=SENTENCE_MODEL, batch_size=64):
    print("Loading sentence-transformer model:", model_name)
    model = SentenceTransformer(model_name)
    texts = []
    for it in items:
        lbl = it.get("label") or ""
        desc = it.get("meta", {}).get("description", "") or ""
        combined = lbl + ". " + desc
        texts.append(combined)

    print(f"Computing content embeddings for {len(texts)} items...")
    embeddings = model.encode(texts, batch_size=batch_size, show_progress_bar=True, normalize_embeddings=False)
    embeddings = np.array(embeddings, dtype=np.float32)
    print("Content embeddings shape:", embeddings.shape)
    return embeddings

def compute_node2vec_embeddings(G, items, dimensions=NODE2VEC_DIM, workers=4, p=1, q=1, walk_length=80, num_walks=10):
    # Run node2vec on the whole KG (NetworkX graph)
    print("Running Node2Vec on KG: dim", dimensions)
    node2vec = Node2Vec(G, dimensions=dimensions, walk_length=walk_length, num_walks=num_walks,
                        workers=workers, p=p, q=q, quiet=True)
    model = node2vec.fit(window=10, min_count=1, batch_words=4)  # gensim Word2Vec model

    # For each item in items list, try to get embedding from the model
    node_emb = np.zeros((len(items), dimensions), dtype=np.float32)
    for i, it in enumerate(items):
        qid = it["qid"]
        # node ids in KG likely like "place:Name" etc. Use same exact qid.
        if qid in model.wv:
            node_emb[i] = model.wv[qid]
        else:
            # try variants: sometimes KG uses different label cases; fallback to zeros
            node_emb[i] = np.zeros(dimensions, dtype=np.float32)
    print("Node2Vec embeddings shape:", node_emb.shape)
    return node_emb

def build_synthetic_interactions(items, num_users=NUM_SYN_USERS, min_per_user=MIN_ITEMS_PER_USER, max_per_user=MAX_ITEMS_PER_USER):
    # Create a popularity distribution: some items are more popular (e.g., city centers, famous places)
    n_items = len(items)
    base_pop = np.ones(n_items, dtype=np.float32)

    # encourage items that are places/events to be slightly more popular than food (as an example)
    for idx, it in enumerate(items):
        t = it.get("type", "")
        if t == "place":
            base_pop[idx] *= 1.4
        elif t == "event":
            base_pop[idx] *= 1.2
        elif t == "food":
            base_pop[idx] *= 0.9

    # add some random popularity bumps
    bumps = np.random.RandomState(SEED).rand(n_items) * 0.5
    popularity = base_pop + bumps
    popularity = popularity / popularity.sum()

    # Generate interactions
    rows = []
    cols = []
    data = []
    for u in range(num_users):
        k = random.randint(min_per_user, max_per_user)
        # sample without replacement, bias by popularity
        chosen = np.random.choice(n_items, size=min(k, n_items), replace=False, p=popularity)
        for item_idx in chosen:
            # generate implicit feedback weight (1 to 5)
            weight = 1 + int(random.random() * 4)
            rows.append(u)
            cols.append(item_idx)
            data.append(weight)

    # Build sparse matrix (users x items)
    user_count = num_users
    item_count = n_items
    mat = csr_matrix((data, (rows, cols)), shape=(user_count, item_count), dtype=np.float32)
    print("Synthetic interactions matrix shape:", mat.shape, "nnz:", mat.nnz)
    return mat

def compute_item_factors_from_interactions(interactions_csr, n_components=CF_DIM):
    # We want item factors (items x n_components). TruncatedSVD on items-by-users or users-by-items?
    # We'll compute SVD on the (users x items) matrix and take components for items:
    # If interactions is U x I, we can compute item factors by applying SVD on transpose or by doing SVD on interactions and projecting.
    # Using TruncatedSVD on the user-item matrix produces user latent components; to get item vectors, we can compute:
    # item_factors = V * Sigma (i.e., components_.T * Sigma) but TruncatedSVD provides components_ as shape (n_components, n_features)
    # where n_features==n_items when applied to users x items. So components_.T * Sigma gives item factors.
    print("Computing TruncatedSVD for collaborative factors (dim {})".format(n_components))
    svd = TruncatedSVD(n_components=n_components, random_state=SEED)
    svd.fit(interactions_csr)  # fit on users x items

    # components_ shape: (n_components, n_items)
    components = svd.components_  # numpy array
    sigma = svd.singular_values_  # length n_components

    # item_factors = components_.T * sigma
    item_factors = (components.T * sigma).astype(np.float32)  # shape (n_items, n_components)
    print("Item factors shape:", item_factors.shape)
    return item_factors

def l2_normalize_rows(x, eps=1e-12):
    norms = np.linalg.norm(x, axis=1, keepdims=True)
    norms = np.maximum(norms, eps)
    return x / norms

# --- Main pipeline ---
def main():
    print("=== TRAIN PIPELINE START ===")
    # 1) load items & KG
    items, qid_to_idx = unify_items()
    if not items:
        raise RuntimeError("No items loaded. Check your CSV files in data/")

    if not os.path.exists(KG_IN):
        raise FileNotFoundError(f"KG file not found at {KG_IN}. Run kg_build.py first.")
    with open(KG_IN, "rb") as f:
        G = pickle.load(f)
    print("Loaded KG:", KG_IN, "Nodes:", G.number_of_nodes(), "Edges:", G.number_of_edges())

    # 2) content embeddings
    content_emb = compute_content_embeddings(items)
    np.save(CONTENT_EMB_OUT, content_emb)
    print("Saved content embeddings:", CONTENT_EMB_OUT)

    # 3) node2vec embeddings
    node2vec_emb = compute_node2vec_embeddings(G, items, dimensions=NODE2VEC_DIM)
    np.save(NODE2VEC_EMB_OUT, node2vec_emb)
    print("Saved node2vec embeddings:", NODE2VEC_EMB_OUT)

    # 4) collaborative synthetic interactions -> SVD factors
    interactions = build_synthetic_interactions(items)
    item_factors = compute_item_factors_from_interactions(interactions, n_components=CF_DIM)
    np.save(ITEM_FACTORS_OUT, item_factors)
    print("Saved item factors:", ITEM_FACTORS_OUT)

    # 5) combine embeddings
    # normalize each modality, then concatenate
    content_emb_n = l2_normalize_rows(content_emb)
    node2vec_emb_n = l2_normalize_rows(node2vec_emb)
    item_factors_n = l2_normalize_rows(item_factors)

    combined = np.concatenate([content_emb_n, node2vec_emb_n, item_factors_n], axis=1).astype(np.float32)
    print("Combined embeddings shape:", combined.shape)
    # Save the modality arrays (already saved) and also save combined via hnsw index
    # but we also store combined array as node2vec_embeddings.npy? No — create a combined file implicitly via index
    # We'll save combined as a numpy file too for debugging
    combined_np_out = os.path.join(ART_DIR, "combined_item_embeddings.npy")
    np.save(combined_np_out, combined)
    print("Saved combined embeddings:", combined_np_out)

    # 6) Build HNSW index
    n_items, dim = combined.shape
    global FINAL_DIM
    FINAL_DIM = dim
    print(f"Building HNSW index: n_items={n_items}, dim={dim}, space={HNSW_SPACE}")
    p = hnswlib.Index(space=HNSW_SPACE, dim=dim)
    p.init_index(max_elements=n_items, ef_construction=HNSW_EF_CONSTRUCTION, M=HNSW_M)
    p.set_ef(HNSW_EF_SEARCH)

    # If using "cosine" space we should ensure vectors are normalized (they are)
    p.add_items(combined, np.arange(n_items))
    p.save_index(HNSW_OUT)
    print("Saved HNSW index to:", HNSW_OUT)

    # 7) Save mapping (index->qid & metadata)
    item_map = {}
    for idx, it in enumerate(items):
        item_map[idx] = {
            "qid": it["qid"],
            "label": it.get("label"),
            "type": it.get("type"),
            "city": it.get("city"),
            "meta": it.get("meta", {})
        }
    with open(ITEM_MAP_OUT, "w", encoding="utf-8") as f:
        json.dump(item_map, f, ensure_ascii=False, indent=2)
    print("Saved item map:", ITEM_MAP_OUT)

    print("=== TRAIN PIPELINE COMPLETE ===")
    print("Artifacts written to:", ART_DIR)
    print("Files:")
    for pth in [CONTENT_EMB_OUT, NODE2VEC_EMB_OUT, ITEM_FACTORS_OUT, combined_np_out, HNSW_OUT, ITEM_MAP_OUT]:
        print(" -", pth)

if __name__ == "__main__":
    main()
