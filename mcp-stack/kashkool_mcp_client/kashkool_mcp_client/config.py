"""
Configuration System — Centralized configuration for the Cognitive MCP Architecture.
Supports YAML, JSON, environment variables, and programmatic configuration.
"""
import os
import json
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any, Dict, List, Optional, Union
from enum import Enum


class ConfigFormat(Enum):
    JSON = "json"
    YAML = "yaml"
    ENV = "env"


@dataclass
class ServerConfig:
    """Configuration for a single MCP server."""
    name: str
    command: List[str]
    tools: List[str]
    env: Dict[str, str] = field(default_factory=dict)
    timeout: int = 60
    health_check: Optional[str] = None
    enabled: bool = True
    priority: int = 0  # Higher = preferred


@dataclass
class LLMConfig:
    """LLM provider configuration."""
    provider: str = "demo"  # demo, openai, anthropic, ollama, custom
    model: str = "gpt-4"
    api_key: Optional[str] = None
    base_url: Optional[str] = None
    temperature: float = 0.7
    max_tokens: int = 4000
    timeout: int = 60
    max_retries: int = 3


@dataclass
class MemoryConfig:
    """Memory palace configuration."""
    capacity: int = 10000
    consolidation_threshold: float = 0.7
    forgetting_curve_factor: float = 0.99
    auto_consolidate_interval: int = 3600  # seconds
    embedding_dimension: int = 384
    similarity_threshold: float = 0.7


@dataclass
class ReasoningConfig:
    """Reasoning engine configuration."""
    default_strategy: str = "chain_of_thought"
    max_steps: int = 10
    max_branches: int = 3
    default_temperature: float = 0.7
    require_verification: bool = True
    self_consistency_samples: int = 5
    tree_exploration_depth: int = 5


@dataclass
class VerificationConfig:
    """Verification core configuration."""
    default_level: str = "cross_reference"
    cache_size: int = 5000
    cache_ttl: int = 3600
    enable_hallucination_detection: bool = True
    calibration_enabled: bool = True
    external_verifiers: Dict[str, str] = field(default_factory=dict)  # name -> endpoint


@dataclass
class RouterConfig:
    """Adaptive router configuration."""
    exploration_factor: float = 1.0
    min_samples_before_exploit: int = 3
    performance_window: int = 100
    quality_weight: float = 0.3
    latency_weight: float = 0.3
    success_rate_weight: float = 0.4


@dataclass
class OrchestratorConfig:
    """Tool orchestrator configuration."""
    max_parallel: int = 5
    default_timeout: float = 30.0
    default_retries: int = 1
    enable_streaming: bool = True
    history_size: int = 100


@dataclass
class PersistenceConfig:
    """Persistence configuration."""
    backend: str = "sqlite"  # json, sqlite, redis
    path: str = "./cognitive_data"
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_db: int = 0
    redis_password: Optional[str] = None
    auto_save_interval: int = 30
    max_memory_nodes: int = 10000
    max_thought_chains: int = 1000
    max_verification_cache: int = 5000


@dataclass
class APIServerConfig:
    """API server configuration."""
    host: str = "0.0.0.0"
    port: int = 8000
    workers: int = 1
    cors_origins: List[str] = field(default_factory=lambda: ["*"])
    enable_websockets: bool = True
    enable_sse: bool = True
    rate_limit: int = 100  # requests per minute
    auth_enabled: bool = False
    api_keys: List[str] = field(default_factory=list)


@dataclass
class LoggingConfig:
    """Logging configuration."""
    level: str = "INFO"
    format: str = "json"
    file: Optional[str] = None
    max_file_size: int = 10 * 1024 * 1024  # 10MB
    backup_count: int = 5
    log_requests: bool = True
    log_reasoning: bool = False


@dataclass
class CognitiveMCPConfig:
    """Main configuration class for the entire Cognitive MCP Architecture."""
    servers: List[ServerConfig] = field(default_factory=list)
    llm: LLMConfig = field(default_factory=LLMConfig)
    memory: MemoryConfig = field(default_factory=MemoryConfig)
    reasoning: ReasoningConfig = field(default_factory=ReasoningConfig)
    verification: VerificationConfig = field(default_factory=VerificationConfig)
    router: RouterConfig = field(default_factory=RouterConfig)
    orchestrator: OrchestratorConfig = field(default_factory=OrchestratorConfig)
    persistence: PersistenceConfig = field(default_factory=PersistenceConfig)
    api: APIServerConfig = field(default_factory=APIServerConfig)
    logging: LoggingConfig = field(default_factory=LoggingConfig)

    # Metadata
    version: str = "1.0.0"
    environment: str = "development"
    debug: bool = False

    @classmethod
    def default(cls) -> "CognitiveMCPConfig":
        """Create default configuration with all Kashkool MCP servers."""
        config = cls()

        # Default servers (Kashkool stack)
        config.servers = [
            ServerConfig(
                name="zenrows",
                command=["npx", "-y", "@zenrows/mcp"],
                tools=["scrape", "screenshot", "extract"],
                env={},
                priority=10
            ),
            ServerConfig(
                name="playwright",
                command=["npx", "-y", "@playwright/mcp"],
                tools=["navigate", "click", "fill", "screenshot", "evaluate"],
                env={},
                priority=5
            ),
            ServerConfig(
                name="firecrawl",
                command=["npx", "-y", "firecrawl-mcp"],
                tools=["scrape", "search", "crawl", "map"],
                env={"FIRECRAWL_API_KEY": "${FIRECRAWL_API_KEY}"},
                priority=15
            ),
            ServerConfig(
                name="jina",
                command=["npx", "-y", "jina-reader-mcp-server"],
                tools=["read", "search"],
                env={"JINA_API_KEY": "${JINA_API_KEY}"},
                priority=10
            ),
            ServerConfig(
                name="apify",
                command=["npx", "-y", "@apify/actors-mcp-server"],
                tools=["run_actor", "get_dataset"],
                env={"APIFY_TOKEN": "${APIFY_TOKEN}"},
                priority=5
            ),
            ServerConfig(
                name="youtube",
                command=["npx", "-y", "@fabriqa.ai/youtube-transcript-mcp"],
                tools=["get_transcript", "search_videos"],
                env={},
                priority=10
            ),
            ServerConfig(
                name="sequential",
                command=["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
                tools=["think"],
                env={},
                priority=10
            ),
            ServerConfig(
                name="fetch",
                command=["npx", "-y", "mcp-fetch-server"],
                tools=["fetch"],
                env={},
                priority=5
            ),
            ServerConfig(
                name="string",
                command=["npx", "-y", "@usestring/mcp"],
                tools=["search", "fetch"],
                env={"STRING_API_KEY": "${STRING_API_KEY}"},
                priority=5
            ),
        ]

        return config

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return asdict(self)

    def to_json(self, indent: int = 2) -> str:
        """Convert to JSON string."""
        return json.dumps(self.to_dict(), indent=indent, default=str)

    def save(self, path: Union[str, Path], format: ConfigFormat = ConfigFormat.JSON):
        """Save configuration to file."""
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)

        if format == ConfigFormat.JSON:
            path.write_text(self.to_json(), encoding="utf-8")
        elif format == ConfigFormat.YAML:
            try:
                import yaml
                path.write_text(yaml.dump(self.to_dict(), allow_unicode=True), encoding="utf-8")
            except ImportError:
                raise RuntimeError("PyYAML not installed. Run: pip install pyyaml")
        else:
            raise ValueError(f"Unsupported format: {format}")

    @classmethod
    def load(cls, path: Union[str, Path], format: ConfigFormat = ConfigFormat.JSON) -> "CognitiveMCPConfig":
        """Load configuration from file."""
        path = Path(path)
        if not path.exists():
            raise FileNotFoundError(f"Config file not found: {path}")

        if format == ConfigFormat.JSON:
            data = json.loads(path.read_text(encoding="utf-8"))
        elif format == ConfigFormat.YAML:
            try:
                import yaml
                data = yaml.safe_load(path.read_text(encoding="utf-8"))
            except ImportError:
                raise RuntimeError("PyYAML not installed. Run: pip install pyyaml")
        else:
            raise ValueError(f"Unsupported format: {format}")

        return cls.from_dict(data)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "CognitiveMCPConfig":
        """Create config from dictionary."""
        config = cls()

        # Load servers
        if "servers" in data:
            config.servers = [
                ServerConfig(**s) if isinstance(s, dict) else s
                for s in data["servers"]
            ]

        # Load nested configs
        for field_name in ["llm", "memory", "reasoning", "verification", "router",
                           "orchestrator", "persistence", "api", "logging"]:
            if field_name in data:
                field_data = data[field_name]
                if isinstance(field_data, dict):
                    field_class = cls.__dataclass_fields__[field_name].type
                    setattr(config, field_name, field_class(**field_data))

        # Load metadata
        for key in ["version", "environment", "debug"]:
            if key in data:
                setattr(config, key, data[key])

        return config

    def resolve_env_vars(self) -> "CognitiveMCPConfig":
        """Resolve environment variable placeholders in config."""
        import re

        def resolve_value(value: Any) -> Any:
            if isinstance(value, str):
                # Replace ${VAR_NAME} with environment variable
                def replace_match(match):
                    var_name = match.group(1)
                    return os.getenv(var_name, match.group(0))

                return re.sub(r"\$\{([^}]+)\}", replace_match, value)
            elif isinstance(value, dict):
                return {k: resolve_value(v) for k, v in value.items()}
            elif isinstance(value, list):
                return [resolve_value(v) for v in value]
            return value

        # Create a copy with resolved values
        config_dict = self.to_dict()
        resolved_dict = resolve_value(config_dict)
        return self.from_dict(resolved_dict)

    def get_enabled_servers(self) -> List[ServerConfig]:
        """Get only enabled servers, sorted by priority."""
        return sorted(
            [s for s in self.servers if s.enabled],
            key=lambda s: s.priority,
            reverse=True
        )

    def get_server(self, name: str) -> Optional[ServerConfig]:
        """Get server config by name."""
        for server in self.servers:
            if server.name == name:
                return server
        return None

    def validate(self) -> List[str]:
        """Validate configuration and return list of issues."""
        issues = []

        # Check for duplicate server names
        names = [s.name for s in self.servers]
        if len(names) != len(set(names)):
            issues.append("Duplicate server names found")

        # Check LLM config
        if self.llm.provider not in ["demo", "openai", "anthropic", "ollama", "custom"]:
            issues.append(f"Unknown LLM provider: {self.llm.provider}")

        if self.llm.provider != "demo" and not self.llm.api_key:
            issues.append(f"API key required for provider: {self.llm.provider}")

        # Check persistence
        if self.persistence.backend not in ["json", "sqlite", "redis"]:
            issues.append(f"Unknown persistence backend: {self.persistence.backend}")

        # Check API config
        if self.api.port < 1 or self.api.port > 65535:
            issues.append("Invalid API port")

        return issues


# ==================== CONFIGURATION MANAGER ====================

class ConfigManager:
    """Manages configuration loading, merging, and hot-reloading."""

    def __init__(self, config: Optional[CognitiveMCPConfig] = None):
        self.config = config or CognitiveMCPConfig.default()
        self._watchers: List[callable] = []
        self._file_path: Optional[Path] = None
        self._file_format: ConfigFormat = ConfigFormat.JSON

    def load_from_file(self, path: Union[str, Path], format: ConfigFormat = ConfigFormat.JSON):
        """Load configuration from file."""
        self._file_path = Path(path)
        self._file_format = format
        self.config = CognitiveMCPConfig.load(path, format)
        self.config = self.config.resolve_env_vars()
        self._notify_watchers()

    def load_from_env(self, prefix: str = "KASHKOOL_"):
        """Load configuration from environment variables."""
        env_config = {}

        # Map environment variables to config fields
        mappings = {
            f"{prefix}LLM_PROVIDER": ("llm", "provider"),
            f"{prefix}LLM_MODEL": ("llm", "model"),
            f"{prefix}LLM_API_KEY": ("llm", "api_key"),
            f"{prefix}LLM_BASE_URL": ("llm", "base_url"),
            f"{prefix}LLM_TEMPERATURE": ("llm", "temperature"),
            f"{prefix}MEMORY_CAPACITY": ("memory", "capacity"),
            f"{prefix}PERSISTENCE_BACKEND": ("persistence", "backend"),
            f"{prefix}PERSISTENCE_PATH": ("persistence", "path"),
            f"{prefix}API_HOST": ("api", "host"),
            f"{prefix}API_PORT": ("api", "port"),
            f"{prefix}ENVIRONMENT": ("environment",),
            f"{prefix}DEBUG": ("debug",),
        }

        for env_var, path in mappings.items():
            value = os.getenv(env_var)
            if value is not None:
                # Navigate to the target field
                target = self.config
                for part in path[:-1]:
                    target = getattr(target, part)

                # Convert type
                field_type = type(getattr(target, path[-1]))
                if field_type == bool:
                    value = value.lower() in ("true", "1", "yes")
                elif field_type == int:
                    value = int(value)
                elif field_type == float:
                    value = float(value)

                setattr(target, path[-1], value)

        self._notify_watchers()

    def save_to_file(self, path: Optional[Union[str, Path]] = None, format: Optional[ConfigFormat] = None):
        """Save configuration to file."""
        path = Path(path) if path else self._file_path
        format = format or self._file_format

        if not path:
            raise ValueError("No file path specified")

        self.config.save(path, format)
        self._file_path = path
        self._file_format = format

    def watch(self, callback: callable):
        """Register a callback for configuration changes."""
        self._watchers.append(callback)

    def _notify_watchers(self):
        """Notify all watchers of configuration change."""
        for watcher in self._watchers:
            try:
                watcher(self.config)
            except Exception as e:
                print(f"Config watcher error: {e}")

    def get(self, path: str, default: Any = None) -> Any:
        """Get a configuration value by dot-notation path."""
        parts = path.split(".")
        value = self.config
        for part in parts:
            if hasattr(value, part):
                value = getattr(value, part)
            elif isinstance(value, dict) and part in value:
                value = value[part]
            else:
                return default
        return value

    def set(self, path: str, value: Any):
        """Set a configuration value by dot-notation path."""
        parts = path.split(".")
        target = self.config
        for part in parts[:-1]:
            if hasattr(target, part):
                target = getattr(target, part)
            elif isinstance(target, dict) and part in target:
                target = target[part]
            else:
                raise KeyError(f"Path not found: {path}")

        last_part = parts[-1]
        if hasattr(target, last_part):
            setattr(target, last_part, value)
        elif isinstance(target, dict):
            target[last_part] = value
        else:
            raise KeyError(f"Path not found: {path}")

        self._notify_watchers()

    def merge(self, other: "CognitiveMCPConfig", strategy: str = "override") -> "CognitiveMCPConfig":
        """Merge another config into this one."""
        if strategy == "override":
            # Simple override - replace non-None values
            self_dict = self.config.to_dict()
            other_dict = other.to_dict()

            def merge_dicts(base: dict, override: dict) -> dict:
                result = base.copy()
                for key, value in override.items():
                    if value is not None:
                        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                            result[key] = merge_dicts(result[key], value)
                        else:
                            result[key] = value
                return result

            merged = merge_dicts(self_dict, other_dict)
            self.config = CognitiveMCPConfig.from_dict(merged)
            self._notify_watchers()

        return self.config


# ==================== PRESET CONFIGURATIONS ====================

def create_development_config() -> CognitiveMCPConfig:
    """Create development configuration."""
    config = CognitiveMCPConfig.default()
    config.environment = "development"
    config.debug = True
    config.logging.level = "DEBUG"
    config.logging.log_reasoning = True
    config.api.workers = 1
    config.persistence.backend = "sqlite"
    config.persistence.path = "./dev_cognitive_data"
    config.llm.provider = "demo"
    return config


def create_production_config() -> CognitiveMCPConfig:
    """Create production configuration."""
    config = CognitiveMCPConfig.default()
    config.environment = "production"
    config.debug = False
    config.logging.level = "INFO"
    config.logging.log_reasoning = False
    config.api.workers = 4
    config.persistence.backend = "redis"
    config.persistence.redis_host = "redis"
    config.api.auth_enabled = True
    config.api.rate_limit = 1000
    return config


def create_testing_config() -> CognitiveMCPConfig:
    """Create testing configuration."""
    config = CognitiveMCPConfig.default()
    config.environment = "testing"
    config.debug = True
    config.logging.level = "WARNING"
    config.persistence.backend = "json"
    config.persistence.path = "./test_cognitive_data"
    config.llm.provider = "demo"
    config.reasoning.max_steps = 3
    config.reasoning.max_branches = 2
    config.verification.default_level = "basic"
    return config


def create_minimal_config() -> CognitiveMCPConfig:
    """Create minimal configuration (only essential servers)."""
    config = CognitiveMCPConfig.default()
    config.servers = [
        ServerConfig(
            name="firecrawl",
            command=["npx", "-y", "firecrawl-mcp"],
            tools=["scrape", "search"],
            env={"FIRECRAWL_API_KEY": "${FIRECRAWL_API_KEY}"},
            priority=10
        ),
        ServerConfig(
            name="sequential",
            command=["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
            tools=["think"],
            env={},
            priority=10
        ),
    ]
    return config


# ==================== CONVENIENCE FUNCTIONS ====================

_default_manager: Optional[ConfigManager] = None


def get_config_manager() -> ConfigManager:
    """Get or create the default config manager."""
    global _default_manager
    if _default_manager is None:
        _default_manager = ConfigManager()
    return _default_manager


def load_config(
    path: Optional[Union[str, Path]] = None,
    format: ConfigFormat = ConfigFormat.JSON,
    env_prefix: str = "KASHKOOL_"
) -> CognitiveMCPConfig:
    """Load configuration from file and environment."""
    manager = get_config_manager()

    if path:
        manager.load_from_file(path, format)

    manager.load_from_env(env_prefix)

    # Validate
    issues = manager.config.validate()
    if issues:
        print(f"⚠️  Configuration issues: {issues}")

    return manager.config


def create_config(preset: str = "default") -> CognitiveMCPConfig:
    """Create a configuration from a preset."""
    presets = {
        "default": CognitiveMCPConfig.default,
        "development": create_development_config,
        "production": create_production_config,
        "testing": create_testing_config,
        "minimal": create_minimal_config,
    }

    if preset not in presets:
        raise ValueError(f"Unknown preset: {preset}. Available: {list(presets.keys())}")

    return presets[preset]()


# ==================== EXAMPLE USAGE ====================

if __name__ == "__main__":
    # Create default config
    config = CognitiveMCPConfig.default()

    # Save to file
    config.save("config.json", ConfigFormat.JSON)
    print("Saved default config to config.json")

    # Load from file
    loaded = CognitiveMCPConfig.load("config.json")
    print(f"Loaded config with {len(loaded.servers)} servers")

    # Create from preset
    dev_config = create_development_config()
    print(f"Dev config: {dev_config.environment}, debug={dev_config.debug}")

    # Config manager
    manager = ConfigManager(dev_config)
    manager.watch(lambda c: print(f"Config changed: {c.environment}"))
    manager.set("llm.temperature", 0.9)
    print(f"New temperature: {manager.get('llm.temperature')}")