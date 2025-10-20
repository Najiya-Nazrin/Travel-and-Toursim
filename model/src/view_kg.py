import pickle
import networkx as nx
import matplotlib.pyplot as plt

# === Load KG ===
with open("../artifacts/kg_graph.pkl", "rb") as f:
    G = pickle.load(f)

# === Optional: Filter a subgraph for readability ===
# For example, show only first 50 nodes
sub_nodes = list(G.nodes())[:50]
subgraph = G.subgraph(sub_nodes)

# === Set positions ===
pos = nx.spring_layout(subgraph, k=0.5)  # You can tweak 'k' to spread it out more

# === Draw nodes with labels ===
plt.figure(figsize=(14, 10))
nx.draw_networkx_nodes(subgraph, pos, node_size=500, node_color="skyblue", alpha=0.8)

# Different colors by node type (optional)
colors = {
    "city": "orange",
    "place": "skyblue",
    "type": "lightgreen",
    "event": "lightcoral",
    "food": "khaki",
    "cuisine": "plum"
}
node_colors = [colors.get(data.get('node_type', ''), "gray") for _, data in subgraph.nodes(data=True)]
nx.draw_networkx_nodes(subgraph, pos, node_color=node_colors, node_size=700, alpha=0.9)

# Draw edges
nx.draw_networkx_edges(subgraph, pos, arrows=True)

# Draw labels (node labels)
labels = {n: d.get('label', n) for n, d in subgraph.nodes(data=True)}
nx.draw_networkx_labels(subgraph, pos, labels, font_size=10)

# Optional: Edge labels (like 'located_in', etc.)
edge_labels = {(u, v): d['rel'] for u, v, d in subgraph.edges(data=True)}
nx.draw_networkx_edge_labels(subgraph, pos, edge_labels=edge_labels, font_color='gray', font_size=8)

# Show
plt.title("Knowledge Graph (Partial View)")
plt.axis('off')
plt.tight_layout()
plt.show()
