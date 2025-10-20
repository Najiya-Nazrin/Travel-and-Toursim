"""
kg_build.py
Builds a geographic + semantic Knowledge Graph for travel recommendations.

Design:
---------
- Cities form the backbone of the KG (connected by 'nearby' edges).
- Each city connects to:
    - Attractions / Places
    - Hotels
    - Food items / Restaurants
    - Cultural Events
- Also captures cuisines, diets, and types.

Output:
---------
artifacts/kg_graph.pkl
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

# === Define ordered city sequences for each district ===
CITY_SEQUENCES = {
    "Kozhikode": [
        "Panniyannur", "Vatakara", "Nadapuram", "Payyoli", "Perambra",
        "Koyilandy", "Balussery", "Thamarassery", "Koduvally", "Mukkam",
        "Kakkodi", "Kozhikode", "Chalippuram", "Feroke"
    ],
    "Thrissur": [
        "Kunnamkulam", "Guruvayur", "Chavakkad", "Wadakkanchery", "Mullurkara",
        "Thrissur", "Mannuthy", "Nattika", "Puthukkad", "Irinjalakuda",
        "Koratty", "Chalakudy", "Kodungallur"
    ],
    "Ernakulam": [
        "Paravur", "Aluva", "Eloor", "Kalamassery", "Thrikkakara", "Cheranalloor",
        "Edapally", "Ernakulam", "Kochi", "Mattancherry", "Fort Kochi", "Vypin",
        "Palluruthy", "Kundannoor", "Perumbavoor", "Kothamangalam", "Muvattupuzha", "Piravom"
    ],
    "Kollam": [
        "Kulathupuzha", "Punalur", "Kottarakkara", "Kundara", "Nedumpana",
        "Elampalloor", "Kottamkara", "Thrikkadavoor", "Perinad", "Kollam",
        "Thrikkovilvattom", "Panayam", "Adichanalloor", "Mayyanad", "Meenad",
        "Chavara", "Neendakara", "Thazhuthala", "Poothakkulam", "Vadakkumthala",
        "Panmana", "Karunagappally", "Kulasekharapuram", "Ayanivelikulangara",
        "Oachira", "Thodiyoor", "Thekkumbhagam", "Paravur", "Alappad"
    ],
    "Alappuzha": [
        "Cherthala", "Vayalar", "Mararikulam", "Kanjikkuzhi", "Aryad", "Mannancherry",
        "Alappuzha", "Punnapra", "Ambalappuzha", "Thakazhy", "Kuttanadu", "Ramankary",
        "Neerattupuram", "Thalavady", "Chakara", "Haripad", "Karthikappally", "Kayamkulam",
        "Chennithala", "Mavelikkara", "Chengannur", "Venmony", "Thiruvanvandoor",
        "Nooranad", "Palamel", "Pandalam Thekkekara", "Thamarakulam"
    ],
    "Thiruvananthapuram": [
        "Varkala", "Vakkom", "Keezhattingal", "Kizhuvalam–Koonthalloor", "Azhoor", "Alamcode",
        "Attingal", "Veiloor", "Pallippuram", "Edakkode", "Karakulam", "Nedumangad",
        "Vattappara", "Kudappanakkunnu", "Vattiyoorkavu", "Sreekaryam", "Uliyazhathura",
        "Thiruvananthapuram", "Vilavoorkkal", "Vilappil", "Malayinkeezhu", "Kulathummal",
        "Pallichal", "Kalliyoor", "Venganoor", "Athiyannur", "Kanjiramkulam",
        "Iroopara", "Neyyattinkara", "Parasuvaikkal", "Parassala"
    ]
}

def add_city_backbone(G):
    """Create city nodes and 'nearby' edges within each district sequence."""
    for district, cities in CITY_SEQUENCES.items():
        for city in cities:
            cid = f"city:{city}"
            if not G.has_node(cid):
                G.add_node(cid, label=city, district=district, node_type="city")

        # Connect sequential cities with 'nearby' edges
        for i in range(len(cities) - 1):
            c1, c2 = f"city:{cities[i]}", f"city:{cities[i + 1]}"
            G.add_edge(c1, c2, rel="nearby")
            G.add_edge(c2, c1, rel="nearby")  # bidirectional

def build_kg():
    G = nx.DiGraph()
    add_city_backbone(G)

    # --- ITEMS (places, attractions, hotels) ---
    with open(ITEMS_CSV, newline='', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for r in reader:
            city = r['City'].strip()
            name = r['Name'].strip()
            type_ = (r.get('Type') or "").strip().lower()
            desc = (r.get('Description') or "").strip()
            lat, lon = r.get('Latitude'), r.get('Longitude')

            if not city or not name:
                continue

            city_id = f"city:{city}"
            if not G.has_node(city_id):
                G.add_node(city_id, label=city, node_type="city")

            place_id = f"place:{name}"
            G.add_node(place_id, label=name, node_type="place",
                       description=desc, lat=lat, lon=lon)

            # Link to city
            G.add_edge(place_id, city_id, rel="located_in")

            # Type node (e.g. museum, hotel, park)
            if type_:
                type_id = f"type:{type_}"
                if not G.has_node(type_id):
                    G.add_node(type_id, label=type_, node_type="type")
                G.add_edge(place_id, type_id, rel="instance_of")

            # For hotel-specific nodes, also tag directly
            if "hotel" in type_:
                G.nodes[place_id]["node_type"] = "hotel"

    # --- EVENTS ---
    with open(EVENTS_CSV, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            name = r['Festival Name'].strip()
            city = r['City'].strip()
            location = (r.get('Location') or "").strip()
            start = (r.get('Start Date') or "").strip()
            end = (r.get('End Date') or "").strip()

            if not name or not city:
                continue

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
            city = (r.get('City') or "").strip() or (r.get('Cuisine') or "").strip()
            diet = (r.get('Diet') or "").strip()
            img = (r.get('Image_link') or "").strip()
            lat, lon = r.get('Latitude'), r.get('Longitude')

            if not name:
                continue

            food_id = f"food:{name}"
            G.add_node(food_id, label=name, node_type="food",
                       description=desc, diet=diet, image=img, lat=lat, lon=lon)

            # Cuisine node
            if cuisine:
                cuisine_id = f"cuisine:{cuisine}"
                if not G.has_node(cuisine_id):
                    G.add_node(cuisine_id, label=cuisine, node_type="cuisine")
                G.add_edge(food_id, cuisine_id, rel="belongs_to_cuisine")

            # Diet node
            if diet:
                diet_id = f"diet:{diet.lower()}"
                if not G.has_node(diet_id):
                    G.add_node(diet_id, label=diet, node_type="diet")
                G.add_edge(food_id, diet_id, rel="serves_diet")

            # City linkage
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
