#!/usr/bin/env node
// Start all MCP servers and verify they're running

import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';

const configPath = 'N:/spaceship-ai/projects/kashkool/mcp-stack/mcp-config.json';
const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));

const servers = Object.entries(config.mcpServers).map(([name, cfg]) => ({
  name,
  command: 'cmd',
  args: ['/c', 'N:\\\\spaceship-ai\\\\tools\\\\node-v26.13.1-win-x64\\\\npx.cmd', ...cfg.args],
  env: { ...process.env, ...cfg.env }
}));

async function startServer(server) {
  return new Promise((resolve) => {
    const proc = spawn(server.command, server.args, {
      cwd: 'N:/spaceship-ai/projects/kashkool/mcp-stack',
      env: server.env,
      stdio: ['pipe', 'pipe', 'pipe']
    });
    
    let output = '';
    let errorOutput = '';
    
    proc.stdout.on('data', d => output += d.toString());
    proc.stderr.on('data', d => errorOutput += d.toString());
    
    // Give it 5 seconds to start
    setTimeout(() => {
      if (proc.killed) {
        resolve({ name: server.name, ok: false, error: 'Process killed' });
      } else {
        resolve({ 
          name: server.name, 
          ok: true, 
          pid: proc.pid,
          output: output.trim() || errorOutput.trim() 
        });
      }
    }, 5000);
    
    proc.on('error', err => {
      resolve({ name: server.name, ok: false, error: err.message });
    });
  });
}

async function main() {
  console.log('🚀 Starting all MCP servers...\n');
  
  const results = [];
  for (const server of servers) {
    process.stdout.write(`Starting ${server.name}... `);
    const result = await startServer(server);
    results.push(result);
    console.log(result.ok ? '✅' : '❌');
    if (!result.ok) {
      console.log(`   Error: ${result.error}`);
    } else if (result.output) {
      console.log(`   ${result.output.split('\n')[0]}`);
    }
  }
  
  const passed = results.filter(r => r.ok).length;
  console.log(`\n📊 Results: ${passed}/${results.length} started`);
  
  // Save PIDs for later management
  const pids = results.filter(r => r.ok).map(r => ({ name: r.name, pid: r.pid }));
  fs.writeFileSync(
    'N:/spaceship-ai/projects/kashkool/mcp-stack/server-pids.json',
    JSON.stringify(pids, null, 2)
  );
  console.log('💾 PIDs saved to server-pids.json');
}

main().catch(console.error);