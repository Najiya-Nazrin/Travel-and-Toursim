## 📘 Overview

The knowledge graph integrates data from:
- `items.csv` → tourist spots & hotels  
- `events.csv` → festivals and city events  
- `food.csv` → local dishes and cuisines  

Each entity (city, place, event, food, cuisine, etc.) is represented as a **node**, and their relationships are represented as **edges**.  

currently.
Nodes: 4683 | Edges: 9099

---

## 🧩 Entities and Relationships

### **Node Types**
| Node Type | Description | Example |
|------------|-------------|----------|
| `city` | Central hub representing a location | `city:Jaipur`, `city:Kochi` |
| `place` | Tourist spot, hotel, or attraction | `place:Hawa Mahal`, `place:Hilton Hotel` |
| `type` | Category of place | `type:attraction`, `type:hotel`, `type:zoo` |
| `event` | Festival or cultural event | `event:Onam`, `event:Jaipur Literature Festival` |
| `food` | Local dish or cuisine item | `food:Puttu`, `food:Dal Baati Churma` |
| `cuisine` | Cuisine region | `cuisine:Kerala Cuisine`, `cuisine:Rajasthani Cuisine` |

---

### **Relationships (Edges)**

| Relation | Direction | Meaning | Example |
|-----------|------------|----------|----------|
| `located_in` | `place → city` | Place is located in a city | `Hawa Mahal → Jaipur` |
| `instance_of` | `place → type` | Place belongs to a type | `Hawa Mahal → attraction` |
| `happens_in` | `event → city` | Event takes place in a city | `Onam → Kochi` |
| `available_in` | `food → city` | Dish is available in a city | `Puttu → Kochi` |
| `belongs_to_cuisine` | `food → cuisine` | Dish belongs to a cuisine | `Puttu → Kerala Cuisine` |
| `similar_to` *(future)* | bidirectional | Computed from embeddings | `Hawa Mahal ↔ City Palace` |
| `recommended_for` *(future)* | `place → preference` | Derived from user behavior | `Hawa Mahal → heritage` |

---

## 🛠️ Data Inputs

All input CSV files are stored in the `data/` directory.

### `items.csv`
| Column | Description |
|--------|-------------|
| **City** | City name |
| **Name** | Tourist spot or hotel name |
| **Type** | Category (`museum`, `hotel`, `theme_park`, etc.) |
| **Latitude / Longitude** | Coordinates |
| **Description** | Optional short description |

---

### `events.csv`
| Column | Description |
|--------|-------------|
| **Festival Name** | Event or festival name |
| **City** | Main city where it takes place |
| **Location** | Local area/street (can be `N/A`) |
| **Start Date / End Date** | Duration of the event |

---

### `food.csv`
| Column | Description |
|--------|-------------|
| **No** | Internal index (used for image lookup) |
| **Name** | Dish name |
| **Description** | Optional |
| **Cuisine** | Cuisine type or region |
| **Course / Diet** | (Optional) Type of meal or diet |
| **Image_link** | URL for dish image |
| **Latitude / Longitude** | Optional location info |
