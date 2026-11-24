"""Main Kashkool MCP Client — unified interface for all MCP servers."""
import asyncio
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Union
from dataclasses import asdict

from .models import ScrapeResult, SearchResult, TranscriptResult, PDFResult, ThinkResult


class KashkoolMCP:
    """
    Unified client for all MCP servers in the Kashkool stack.
    
    Usage:
        client = KashkoolMCP()
        
        # Scrape any URL
        result = client.scrape("https://example.com")
        print(result.markdown)
        
        # Search the web
        results = client.search("best python libraries 2024")
        for r in results.results:
            print(r["title"], r["url"])
        
        # Get YouTube transcript
        transcript = client.youtube_transcript("https://youtube.com/watch?v=...")
        print(transcript.full_text)
        
        # Process PDF
        pdf = client.process_pdf("https://example.com/doc.pdf")
        print(pdf.text)
        
        # Sequential thinking
        thought = client.think("How to optimize database queries?")
        print(thought.conclusion)
    """
    
    # Server configurations
    SERVERS = {
        "zenrows": {
            "cmd": ["npx", "-y", "@zenrows/mcp"],
            "tools": ["scrape", "screenshot", "extract"],
            "env": {}
        },
        "playwright": {
            "cmd": ["npx", "-y", "@playwright/mcp"],
            "tools": ["navigate", "click", "fill", "screenshot", "evaluate"],
            "env": {}
        },
        "firecrawl": {
            "cmd": ["npx", "-y", "firecrawl-mcp"],
            "tools": ["scrape", "search", "crawl", "map"],
            "env": {"FIRECRAWL_API_KEY": os.getenv("FIRECRAWL_API_KEY", "")}
        },
        "jina": {
            "cmd": ["npx", "-y", "jina-reader-mcp-server"],
            "tools": ["read", "search"],
            "env": {"JINA_API_KEY": os.getenv("JINA_API_KEY", "")}
        },
        "apify": {
            "cmd": ["npx", "-y", "@apify/actors-mcp-server"],
            "tools": ["run_actor", "get_dataset"],
            "env": {"APIFY_TOKEN": os.getenv("APIFY_TOKEN", "")}
        },
        "youtube": {
            "cmd": ["npx", "-y", "@fabriqa.ai/youtube-transcript-mcp"],
            "tools": ["get_transcript", "search_videos"],
            "env": {}
        },
        "sequential": {
            "cmd": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
            "tools": ["think"],
            "env": {}
        },
        "fetch": {
            "cmd": ["npx", "-y", "mcp-fetch-server"],
            "tools": ["fetch"],
            "env": {}
        },
        "string": {
            "cmd": ["npx", "-y", "@usestring/mcp"],
            "tools": ["search", "fetch"],
            "env": {"STRING_API_KEY": os.getenv("STRING_API_KEY", "")}
        },
    }
    
    # Tool-to-server mapping (which server to use for each operation)
    TOOL_MAP = {
        "scrape": ["firecrawl", "zenrows", "jina", "fetch", "playwright"],
        "search": ["firecrawl", "jina", "string", "apify"],
        "youtube_transcript": ["youtube"],
        "pdf": ["fetch", "jina"],
        "think": ["sequential"],
        "screenshot": ["playwright", "zenrows"],
        "extract": ["zenrows", "firecrawl", "jina"],
    }
    
    def __init__(
        self,
        npx_path: Optional[str] = None,
        timeout: int = 60,
        preferred_servers: Optional[Dict[str, List[str]]] = None
    ):
        """
        Initialize the client.
        
        Args:
            npx_path: Path to npx executable (auto-detected if None)
            timeout: Default timeout in seconds for MCP calls
            preferred_servers: Override TOOL_MAP with custom server preferences
        """
        self.timeout = timeout
        self.preferred_servers = preferred_servers or self.TOOL_MAP
        self.npx_path = npx_path or self._find_npx()
        self._server_cache: Dict[str, subprocess.Popen] = {}
        self._init_check()
    
    def _find_npx(self) -> str:
        """Find npx executable."""
        # Check common locations
        candidates = [
            r"N:\spaceship-ai\tools\node-v26.13.1-win-x64\npx.cmd",
            r"C:\Program Files\nodejs\npx.cmd",
            r"C:\Program Files (x86)\nodejs\npx.cmd",
            "npx",  # fallback to PATH
        ]
        for c in candidates:
            if Path(c).exists() or c == "npx":
                return c
        return "npx"
    
    def _init_check(self):
        """Verify npx works."""
        try:
            result = subprocess.run(
                [self.npx_path, "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode != 0:
                print(f"Warning: npx check failed: {result.stderr}")
        except Exception as e:
            print(f"Warning: npx not found at {self.npx_path}: {e}")
    
    def _get_server_for_tool(self, tool: str) -> List[str]:
        """Get ordered list of servers that support a tool."""
        return self.preferred_servers.get(tool, self.TOOL_MAP.get(tool, []))
    
    def _call_mcp(
        self,
        server_name: str,
        tool: str,
        params: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Call an MCP server tool via stdio.
        
        This uses the MCP protocol over stdin/stdout.
        """
        server_config = self.SERVERS.get(server_name)
        if not server_config:
            return {"error": f"Unknown server: {server_name}"}
        
        # Build the MCP request
        request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": tool,
                "arguments": params
            }
        }
        
        # Start server if not running
        if server_name not in self._server_cache:
            env = {**os.environ, **server_config["env"]}
            try:
                proc = subprocess.Popen(
                    server_config["cmd"],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    env=env,
                    text=True,
                    bufsize=1
                )
                self._server_cache[server_name] = proc
            except Exception as e:
                return {"error": f"Failed to start {server_name}: {e}"}
        
        proc = self._server_cache[server_name]
        
        try:
            # Send request
            request_json = json.dumps(request) + "\n"
            proc.stdin.write(request_json)
            proc.stdin.flush()
            
            # Read response (with timeout)
            import select
            import time
            
            start = time.time()
            while time.time() - start < self.timeout:
                if proc.stdout.readable():
                    line = proc.stdout.readline()
                    if line:
                        try:
                            response = json.loads(line.strip())
                            if "result" in response:
                                return response["result"]
                            elif "error" in response:
                                return {"error": response["error"]}
                        except json.JSONDecodeError:
                            continue
                time.sleep(0.1)
            
            return {"error": f"Timeout calling {server_name}.{tool}"}
            
        except Exception as e:
            return {"error": f"MCP call failed: {e}"}
    
    def _try_servers(self, tool: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """Try multiple servers in order until one succeeds."""
        servers = self._get_server_for_tool(tool)
        last_error = None
        
        for server in servers:
            result = self._call_mcp(server, tool, params)
            if "error" not in result:
                result["_server_used"] = server
                return result
            last_error = result["error"]
        
        return {"error": f"All servers failed for {tool}: {last_error}"}
    
    # ==================== Public API ====================
    
    def scrape(
        self,
        url: str,
        format: str = "markdown",
        extract_schema: Optional[Dict] = None,
        **kwargs
    ) -> ScrapeResult:
        """
        Scrape a web page and return structured content.
        
        Args:
            url: URL to scrape
            format: Output format (markdown, html, text, json)
            extract_schema: Optional JSON schema for structured extraction
            **kwargs: Additional parameters passed to the scraper
        
        Returns:
            ScrapeResult with markdown, html, text, metadata, links, images
        """
        params = {"url": url, "format": format, **kwargs}
        if extract_schema:
            params["extract_schema"] = extract_schema
        
        result = self._try_servers("scrape", params)
        
        if "error" in result:
            return ScrapeResult(
                url=url,
                success=False,
                error=result["error"],
                server_used=result.get("_server_used", "unknown")
            )
        
        # Normalize response from different servers
        return ScrapeResult(
            url=url,
            markdown=result.get("markdown", result.get("content", "")),
            html=result.get("html", ""),
            text=result.get("text", result.get("content", "")),
            metadata=result.get("metadata", {}),
            links=result.get("links", []),
            images=result.get("images", []),
            success=True,
            server_used=result.get("_server_used", "unknown")
        )
    
    def search(
        self,
        query: str,
        limit: int = 10,
        **kwargs
    ) -> SearchResult:
        """
        Search the web.
        
        Args:
            query: Search query
            limit: Maximum number of results
            **kwargs: Additional parameters
        
        Returns:
            SearchResult with list of results (title, url, snippet, etc.)
        """
        params = {"query": query, "limit": limit, **kwargs}
        result = self._try_servers("search", params)
        
        if "error" in result:
            return SearchResult(
                query=query,
                success=False,
                error=result["error"],
                server_used=result.get("_server_used", "unknown")
            )
        
        # Normalize results
        results = result.get("results", result.get("data", []))
        normalized = []
        for r in results[:limit]:
            normalized.append({
                "title": r.get("title", r.get("name", "")),
                "url": r.get("url", r.get("link", "")),
                "snippet": r.get("snippet", r.get("description", r.get("content", ""))),
                "source": r.get("source", "")
            })
        
        return SearchResult(
            query=query,
            results=normalized,
            success=True,
            server_used=result.get("_server_used", "unknown")
        )
    
    def youtube_transcript(
        self,
        video_url: str,
        language: str = "en"
    ) -> TranscriptResult:
        """
        Get YouTube video transcript.
        
        Args:
            video_url: YouTube video URL or video ID
            language: Preferred language code
        
        Returns:
            TranscriptResult with transcript segments and full text
        """
        # Extract video ID if full URL
        import re
        video_id = video_url
        if "youtube.com" in video_url or "youtu.be" in video_url:
            patterns = [
                r"(?:v=|/)([0-9A-Za-z_-]{11}).*",
                r"youtu\.be/([0-9A-Za-z_-]{11})"
            ]
            for p in patterns:
                m = re.search(p, video_url)
                if m:
                    video_id = m.group(1)
                    break
        
        params = {"video_id": video_id, "language": language}
        result = self._try_servers("youtube_transcript", params)
        
        if "error" in result:
            return TranscriptResult(
                video_id=video_id,
                video_url=video_url,
                success=False,
                error=result["error"],
                server_used=result.get("_server_used", "unknown")
            )
        
        transcript = result.get("transcript", result.get("segments", []))
        full_text = " ".join([seg.get("text", "") for seg in transcript])
        
        return TranscriptResult(
            video_id=video_id,
            video_url=video_url,
            transcript=transcript,
            full_text=full_text,
            language=language,
            success=True,
            server_used=result.get("_server_used", "unknown")
        )
    
    def process_pdf(
        self,
        source: str,  # URL or local file path
        **kwargs
    ) -> PDFResult:
        """
        Extract text from PDF.
        
        Args:
            source: PDF URL or local file path
            **kwargs: Additional parameters
        
        Returns:
            PDFResult with extracted text and metadata
        """
        params = {"source": source, **kwargs}
        result = self._try_servers("pdf", params)
        
        if "error" in result:
            return PDFResult(
                source=source,
                success=False,
                error=result["error"],
                server_used=result.get("_server_used", "unknown")
            )
        
        return PDFResult(
            source=source,
            text=result.get("text", result.get("content", "")),
            pages=result.get("pages", result.get("num_pages", 0)),
            metadata=result.get("metadata", {}),
            success=True,
            server_used=result.get("_server_used", "unknown")
        )
    
    def think(
        self,
        problem: str,
        steps: int = 5
    ) -> ThinkResult:
        """
        Use sequential thinking to solve a problem.
        
        Args:
            problem: Problem statement
            steps: Number of thinking steps
        
        Returns:
            ThinkResult with reasoning steps and conclusion
        """
        params = {"problem": problem, "steps": steps}
        result = self._try_servers("think", params)
        
        if "error" in result:
            return ThinkResult(
                success=False,
                error=result["error"],
                server_used=result.get("_server_used", "unknown")
            )
        
        return ThinkResult(
            steps=result.get("steps", []),
            conclusion=result.get("conclusion", result.get("final_answer", "")),
            success=True,
            server_used=result.get("_server_used", "unknown")
        )
    
    def screenshot(
        self,
        url: str,
        full_page: bool = True,
        **kwargs
    ) -> ScrapeResult:
        """Take a screenshot of a web page."""
        params = {"url": url, "full_page": full_page, **kwargs}
        result = self._try_servers("screenshot", params)
        
        if "error" in result:
            return ScrapeResult(
                url=url,
                success=False,
                error=result["error"],
                server_used=result.get("_server_used", "unknown")
            )
        
        return ScrapeResult(
            url=url,
            markdown=f"![Screenshot]({result.get('screenshot', result.get('image', ''))})",
            metadata={"screenshot": result.get("screenshot", result.get("image", ""))},
            success=True,
            server_used=result.get("_server_used", "unknown")
        )
    
    def extract(
        self,
        url: str,
        schema: Dict[str, Any],
        **kwargs
    ) -> ScrapeResult:
        """
        Extract structured data from a page using a JSON schema.
        
        Args:
            url: URL to extract from
            schema: JSON schema defining the extraction structure
            **kwargs: Additional parameters
        
        Returns:
            ScrapeResult with extracted data in metadata
        """
        params = {"url": url, "schema": schema, **kwargs}
        result = self._try_servers("extract", params)
        
        if "error" in result:
            return ScrapeResult(
                url=url,
                success=False,
                error=result["error"],
                server_used=result.get("_server_used", "unknown")
            )
        
        return ScrapeResult(
            url=url,
            markdown=json.dumps(result.get("extracted", result.get("data", {})), indent=2),
            metadata={"extracted": result.get("extracted", result.get("data", {}))},
            success=True,
            server_used=result.get("_server_used", "unknown")
        )
    
    def close(self):
        """Close all MCP server processes."""
        for name, proc in self._server_cache.items():
            try:
                proc.terminate()
                proc.wait(timeout=5)
            except Exception:
                try:
                    proc.kill()
                except Exception:
                    pass
        self._server_cache.clear()
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
    
    # ==================== Async versions ====================
    
    async def ascrape(self, url: str, **kwargs) -> ScrapeResult:
        """Async version of scrape."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, lambda: self.scrape(url, **kwargs))
    
    async def asearch(self, query: str, **kwargs) -> SearchResult:
        """Async version of search."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, lambda: self.search(query, **kwargs))
    
    async def ayoutube_transcript(self, video_url: str, **kwargs) -> TranscriptResult:
        """Async version of youtube_transcript."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, lambda: self.youtube_transcript(video_url, **kwargs))
    
    async def aprocess_pdf(self, source: str, **kwargs) -> PDFResult:
        """Async version of process_pdf."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, lambda: self.process_pdf(source, **kwargs))
    
    async def athink(self, problem: str, **kwargs) -> ThinkResult:
        """Async version of think."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, lambda: self.think(problem, **kwargs))


# Convenience function for quick one-liners
def quick_scrape(url: str, **kwargs) -> ScrapeResult:
    """Quick scrape without managing client lifecycle."""
    with KashkoolMCP() as client:
        return client.scrape(url, **kwargs)


def quick_search(query: str, **kwargs) -> SearchResult:
    """Quick search without managing client lifecycle."""
    with KashkoolMCP() as client:
        return client.search(query, **kwargs)


def quick_youtube(video_url: str, **kwargs) -> TranscriptResult:
    """Quick YouTube transcript without managing client lifecycle."""
    with KashkoolMCP() as client:
        return client.youtube_transcript(video_url, **kwargs)