#!/usr/bin/env node
// Test all MCP servers in the stack

import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';

const npxPath = 'N:/spaceship-ai/tools/node-v26.13.1-win-x64/npx.cmd';

const servers = [
  { name: '@zenrows/mcp', cmd: npxPath, args: ['-y', '@zenrows/mcp', '--version'] },
  { name: '@playwright/mcp', cmd: npxPath, args: ['-y', '@playwright/mcp', '--version'] },
  { name: 'puppeteer-mcp-server', cmd: npxPath, args: ['-y', 'puppeteer-mcp-server', '--version'] },
  { name: 'firecrawl-mcp', cmd: npxPath, args: ['-y', 'firecrawl-mcp', '--version'] },
  { name: '@apify/actors-mcp-server', cmd: npxPath, args: ['-y', '@apify/actors-mcp-server', '--version'] },
  { name: 'jina-reader-mcp-server', cmd: npxPath, args: ['-y', 'jina-reader-mcp-server', '--version'] },
  { name: '@modelcontextprotocol/server-filesystem', cmd: npxPath, args: ['-y', '@modelcontextprotocol/server-filesystem', '--version'] },
  { name: '@beautyfree/modelcontextprotocol-server-github', cmd: npxPath, args: ['-y', '@beautyfree/modelcontextprotocol-server-github', '--version'] },
  { name: 'youtube-transcript-mcp', cmd: npxPath, args: ['-y', 'youtube-transcript-mcp', '--version'] },
];

async function testServer(server) {
  return new Promise((resolve) => {
    const proc = spawn(server.cmd, server.args, { 
      cwd: 'N:\\spaceship-ai\\projects\\kashkool\\mcp-stack',
      timeout: 30000 
    });
    let output = '';
    proc.stdout.on('data', d => output += d.toString());
    proc.stderr.on('data', d => output += d.toString());
    proc.on('close', code => {
      resolve({ name: server.name, ok: code === 0, output: output.trim() });
    });
    proc.on('error', err => {
      resolve({ name: server.name, ok: false, output: err.message });
    });
  });
}

async function main() {
  console.log('🧪 Testing MCP servers...\n');
  const results = [];
  for (const s of servers) {
    process.stdout.write(`Testing ${s.name}... `);
    const r = await testServer(s);
    results.push(r);
    console.log(r.ok ? '✅' : '❌');
    if (!r.ok) console.log(`   ${r.output}`);
  }
  
  const passed = results.filter(r => r.ok).length;
  console.log(`\n📊 Results: ${passed}/${results.length} passed`);
  
  if (passed === results.length) {
    console.log('🎉 All servers working!');
  } else {
    console.log('⚠️  Some servers failed - check output above');
  }
}

main().catch(console.error);