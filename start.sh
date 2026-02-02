#!/bin/bash
# Quickstart script for Agent Monitor

echo "🐱 Agent Monitor Quickstart"
echo "==========================="
echo ""
echo "Installing dependencies..."
mix deps.get

echo ""
echo "Compiling..."
mix compile

echo ""
echo "Starting interactive console..."
echo ""
echo "Once you see the iex prompt, run:"
echo "  Monitor.Console.start()"
echo ""
echo "Then try:"
echo "  Monitor.Console.status()"
echo "  Monitor.Console.add(\"https://api.github.com\")"
echo "  Monitor.Console.check(\"https://api.github.com\")"
echo ""

iex -S mix
