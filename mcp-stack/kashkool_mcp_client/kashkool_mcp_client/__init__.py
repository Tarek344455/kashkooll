"""
Kashkool MCP Client — Unified interface for all MCP servers.
Usage:
    from kashkool_mcp_client import KashkoolMCP
    
    client = KashkoolMCP()
    result = client.scrape("https://example.com")
    print(result.markdown)
"""
from .client import KashkoolMCP
from .models import ScrapeResult, SearchResult, TranscriptResult, PDFResult

__all__ = ["KashkoolMCP", "ScrapeResult", "SearchResult", "TranscriptResult", "PDFResult"]
__version__ = "1.0.0"