
# 🧭 Trip Recommendation System using Knowledge Graph + Embeddings + Collaborative Filtering

## 📘 Overview
This project builds a **hybrid travel recommendation engine** that combines:
- **Content-based similarity** (Sentence-Transformers)
- **Knowledge Graph embeddings** (Node2Vec)
- **Collaborative-style latent factors** (SVD)
- **Fast similarity search** (HNSWLIB)

It recommends **tourist spots, hotels, foods, and cultural events** based on user trip inputs such as:


source, destination, start_date, end_date, diet_preference

```

---

## 🏗️ Architecture Summary

```

+-------------------+       +------------------+       +---------------------+
| Raw CSV Data      |       | Knowledge Graph  |       | Model Training      |
| (items, events,   | --->  | (NetworkX DiGraph)| --->  | Embeddings:         |
|  food)            |       | Nodes + Edges     |       |  • Content (SBERT)  |
|                   |       |                   |       |  • KG (Node2Vec)    |
|                   |       |                   |       |  • CF (SVD)         |
+-------------------+       +------------------+       +---------------------+
|
v
+----------------------+
| Combined Item Index  |
| (HNSWLIB)            |
+----------------------+
|
v
+----------------------+
| Inference /          |
| recommend_trip()     |
+----------------------+

```

---

## 📂 Repository Structure

```

project/
│
├── data/
│   ├── items.csv
│   ├── events.csv
│   └── food.csv
│
├── artifacts/             ← all generated models & data
│   ├── kg_graph.pkl
│   ├── content_embeddings.npy
│   ├── node2vec_embeddings.npy
│   ├── item_factors.npy
│   ├── item_index_hnsw.bin
│   ├── item_map.json
│
├── kg_build.py            ← builds the Knowledge Graph
├── train.py               ← trains all embeddings & builds index
├── inference.py           ← performs recommendation inference
└── README.md              ← this file

```

---

## ⚙️ Step 1. Build Knowledge Graph

### File: `kg_build.py`

**Purpose:**
Builds a directed Knowledge Graph (`networkx.DiGraph`) from CSV data.

**Node Types**
- `city`, `place`, `type`, `event`, `food`, `cuisine`

**Edge Types**
- `located_in (place → city)`
- `instance_of (place → type)`
- `happens_in (event → city)`
- `available_in (food → city)`
- `belongs_to_cuisine (food → cuisine)`

**Output**
```

artifacts/kg_graph.pkl

````

**Run:**
```bash
python kg_build.py
````

**Sample Output:**

```
✅ Knowledge Graph saved: artifacts/kg_graph.pkl
Nodes: 4683 | Edges: 9099
```

---

## 🧠 Step 2. Train Embeddings & Build Index

### File: `train.py`

**Purpose:**
Train three embedding components and build a unified retrieval index.

**Processes:**

1. **Content Embeddings**

   * Model: `sentence-transformers/all-MiniLM-L6-v2`
   * Text: item names + descriptions
   * Output: `artifacts/content_embeddings.npy`

2. **Knowledge Graph Embeddings**

   * Model: Node2Vec (via `stellargraph`)
   * Input: `kg_graph.pkl`
   * Output: `artifacts/node2vec_embeddings.npy`

3. **Collaborative Filtering Factors**

   * Synthetic or provided user–item interactions
   * Decomposed via SVD
   * Output: `artifacts/item_factors.npy`

4. **Combined Item Representation**

   * Concatenate all embeddings: `[content | kg | cf]`
   * Build **HNSWLIB index** for fast cosine similarity search
   * Save mapping file: `artifacts/item_map.json`

**Run:**

```bash
python train.py
```

**Outputs:**

```
✅ Saved embeddings & index to artifacts/
```

---

## 🚀 Step 3. Run Inference / Recommendation

### File: `inference.py`

**Purpose:**
Load all artifacts and perform trip-specific recommendations.

**CLI Usage:**

```bash
python inference.py \
    --source "Kozhikode" \
    --destination "Kochi" \
    --start_date "20 Oct 2025" \
    --end_date "25 Oct 2025" \
    --diet "Non-Veg"
```

**Sample Output:**

```
Loading artifacts...
Loaded HNSW index with 6071 items.
Loaded KG: 4683 nodes, 9099 edges
Running recommendation for: {...}

=== Recommended Trip Plan ===

RECOMMENDED_SPOTS:
 - Fort Kochi Residency [score=0.484]
 - Kochi Tourist Boating Centre [score=0.482]
 - The Postcard Mandalay Hall, Kochi [score=0.482]
 ...

HOTELS:
 - Le Maritime Kochi [score=0.483]
 - The Postcard Mandalay Hall, Kochi [score=0.482]
 ...

FOOD:
 - Appam with Stew [score=0.480]
 - Kerala Fish Curry Meals [score=0.337]
 ...

CULTURAL_EVENTS:
 - Kochi Metro Short Film Fest [score=0.504]
 - Cochin Carnival [score=0.359]
 ...
```

---

## 🧩 4️⃣ Scoring Logic

Each recommended item gets a **priority_score** computed from:

| Component                | Description                                                                | Weight (default) |
| ------------------------ | -------------------------------------------------------------------------- | ---------------- |
| **Content similarity**   | Sentence-Transformer embedding similarity between query text and item text | 0.5              |
| **KG proximity**         | Inverse shortest-path distance from destination city node                  | 0.3              |
| **Collaborative factor** | Popularity / latent similarity from SVD                                    | 0.2              |

Final combined score is normalized and ranked.

---

## 🧱 5️⃣ Categories in Output

| Output Key            | Source       | Filtering Logic                             |
| --------------------- | ------------ | ------------------------------------------- |
| **recommended_spots** | `items.csv`  | Top-ranked “places”                         |
| **hotels**            | `items.csv`  | Where type contains “hotel”, “resort”, etc. |
| **food**              | `food.csv`   | Filtered by `diet` (Veg / Non-Veg)          |
| **cultural_events**   | `events.csv` | Filtered by city & date range               |

---

## 🧹 6️⃣ Deduplication Fix

Initially, some results (e.g., “Fort Kochi Residency”) appeared multiple times.
We added a **deduplication step** in inference based on normalized `label` values:

```python
def dedup_by_label(lst):
    seen = set()
    deduped = []
    for item in lst:
        key = item["label"].strip().lower()
        if key not in seen:
            seen.add(key)
            deduped.append(item)
    return deduped
```

This ensures each unique entity appears only once per category.

---

## 📆 7️⃣ Optional Enhancements

### a) **Event Date Filtering**

Events are filtered to match the user’s trip date range using start/end date fields.

```python
def filter_events_by_date(events, start_date, end_date):
    # keeps only events overlapping trip dates
```

### b) **Diet-based Food Filtering**

Foods filtered by `"Diet"` field matching user `"Veg"` or `"Non-Veg"` preference.

### c) **Destination Weight**

Graph proximity (`shortest_path_length`) from destination city node is used to increase relevance.

---

## 🧰 8️⃣ Debugging Notes

### ⚠️ Issue: `malloc(): invalid size (unsorted)`

**Cause:** Mismatch between query embedding dimension (384) and index dimension (≈576).
**Fix:** Pad query embedding with zeros for Node2Vec + CF parts before querying HNSW index.

Added in inference:

```python
if q_emb.shape[1] < total_dim:
    pad = np.zeros((1, total_dim - content_dim), dtype=np.float32)
    q_emb = np.concatenate([q_emb, pad], axis=1)
```

---

## 📦 9️⃣ Artifacts Produced

| File                      | Description                    |
| ------------------------- | ------------------------------ |
| `kg_graph.pkl`            | Pickled NetworkX DiGraph       |
| `content_embeddings.npy`  | SBERT embeddings of items      |
| `node2vec_embeddings.npy` | Graph embeddings from Node2Vec |
| `item_factors.npy`        | Latent factors from SVD        |
| `item_index_hnsw.bin`     | HNSWLIB cosine index           |
| `item_map.json`           | Metadata map for index lookup  |

---

## 🔮 10️⃣ Future Extensions

* Integrate **weather**, **seasonal popularity**, or **real-time events**
* Add **route optimization** for itinerary generation
* Introduce **user personalization** (past interactions or preferences)
* Replace synthetic CF data with **real user–item matrix**
* Deploy as **REST API / FastAPI service**

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch (`feature/xyz`)
3. Add or modify modules
4. Submit a pull request with description

---

## 🧩 Reference Notes for Future ChatGPT Usage

If you want to modify or extend this project later, you can give ChatGPT this README and ask, for example:

* “Add event date filtering in inference.py.”
* “Change Node2Vec to GraphSAGE.”
* “Add itinerary ranking based on travel duration.”
* “Explain how CF factors are computed in train.py.”

This README contains all necessary context for ChatGPT to understand the full pipeline.

---

## 🏁 Example End-to-End Run

```bash
# Step 1. Build Knowledge Graph
python kg_build.py

# Step 2. Train embeddings & build index
python train.py

# Step 3. Run inference
python inference.py \
  --source "Kozhikode" \
  --destination "Kochi" \
  --start_date "20 Oct 2025" \
  --end_date "25 Oct 2025" \
  --diet "Non-Veg"
```
