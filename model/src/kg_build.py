"""
kg_build.py
Builds a knowledge graph (NetworkX DiGraph) from items.csv, events.csv, and food.csv.

Nodes:
- city, place, type, event, food, cuisine

Edges:
- located_in (place -> city)
- instance_of (place -> type)
- happens_in (event -> city)
- available_in (food -> city)
- belongs_to_cuisine (food -> cuisine)

Output:
- artifacts/kg_graph.pkl
"""

import os
import csv
import pickle
import networkx as nx

# === Paths ===
ROOT = os.path.join(os.path.dirname(__file__), "..")
DATA_DIR = os.path.join(ROOT, "data")
ART_DIR = os.path.join(ROOT, "artifacts")
os.makedirs(ART_DIR, exist_ok=True)

ITEMS_CSV = os.path.join(DATA_DIR, "items.csv")
EVENTS_CSV = os.path.join(DATA_DIR, "events.csv")
FOOD_CSV = os.path.join(DATA_DIR, "food.csv")
KG_OUT = os.path.join(ART_DIR, "kg_graph.pkl")

# === Build Graph ===
def build_kg():
    G = nx.DiGraph()

    # --- ITEMS ---
    with open(ITEMS_CSV, newline='', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for r in reader:
            city = r['City'].strip()
            name = r['Name'].strip()
            type_ = (r.get('Type') or "").strip().lower()
            desc = (r.get('Description') or "").strip()
            lat, lon = r.get('Latitude'), r.get('Longitude')

            # City node
            city_id = f"city:{city}"
            if not G.has_node(city_id):
                G.add_node(city_id, label=city, node_type="city")

            # Place node
            place_id = f"place:{name}"
            G.add_node(place_id, label=name, node_type="place",
                       description=desc, lat=lat, lon=lon)

            # located_in edge
            G.add_edge(place_id, city_id, rel="located_in")

            # Type node (museum, hotel, etc.)
            if type_:
                type_id = f"type:{type_}"
                if not G.has_node(type_id):
                    G.add_node(type_id, label=type_, node_type="type")
                G.add_edge(place_id, type_id, rel="instance_of")

    # --- EVENTS ---
    with open(EVENTS_CSV, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            name = r['Festival Name'].strip()
            city = r['City'].strip()
            location = (r.get('Location') or "").strip()
            start = (r.get('Start Date') or "").strip()
            end = (r.get('End Date') or "").strip()

            city_id = f"city:{city}"
            if not G.has_node(city_id):
                G.add_node(city_id, label=city, node_type="city")

            event_id = f"event:{name}"
            G.add_node(event_id, label=name, node_type="event",
                       location=location, start=start, end=end)

            G.add_edge(event_id, city_id, rel="happens_in")

    # --- FOOD ---
    with open(FOOD_CSV, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            name = r['Name'].strip()
            desc = (r.get('Description') or "").strip()
            cuisine = (r.get('Cuisine') or "").strip()
            city = (r.get('Cuisine') or "").strip()  # using cuisine as place indicator if city missing
            diet = (r.get('Diet') or "").strip()
            img = (r.get('Image_link') or "").strip()
            lat, lon = r.get('Latitude'), r.get('Longitude')

            food_id = f"food:{name}"
            G.add_node(food_id, label=name, node_type="food",
                       description=desc, diet=diet, image=img, lat=lat, lon=lon)

            # Cuisine node
            if cuisine:
                cuisine_id = f"cuisine:{cuisine}"
                if not G.has_node(cuisine_id):
                    G.add_node(cuisine_id, label=cuisine, node_type="cuisine")
                G.add_edge(food_id, cuisine_id, rel="belongs_to_cuisine")

            # Available in city
            if city:
                city_id = f"city:{city}"
                if not G.has_node(city_id):
                    G.add_node(city_id, label=city, node_type="city")
                G.add_edge(food_id, city_id, rel="available_in")

    # --- Save KG ---
    with open(KG_OUT, "wb") as f:
        pickle.dump(G, f)

    print(f"✅ Knowledge Graph saved: {KG_OUT}")
    print(f"Nodes: {G.number_of_nodes()} | Edges: {G.number_of_edges()}")

# === Run ===
if __name__ == "__main__":
    build_kg()
