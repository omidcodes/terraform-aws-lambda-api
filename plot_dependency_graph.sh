#!/usr/bin/env bash

set -e  # Exit on error

echo "🔧 Installing Graphviz (if not already installed)..."
sudo apt update -y
sudo apt install -y graphviz

echo "📊 Generating Terraform graph..."
terraform graph > graph.dot

echo "🖼️ Converting graph to PNG..."
dot -Tpng graph.dot -o graph.png

echo "✅ Done! File generated: graph.png"
