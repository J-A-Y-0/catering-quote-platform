"""Provider adapters. Each one only translates between our message format and an API.

Pick one with make_llm('anthropic' | 'openai' | ...). SDKs are imported lazily, so
nothing needs installing until a provider is chosen.
"""


def make_llm(provider, **kwargs):
    provider = (provider or '').lower()
    if provider in ('anthropic', 'claude'):
        from .anthropic_provider import AnthropicLLM
        return AnthropicLLM(**kwargs)
    if provider in ('openai', 'gpt'):
        from .openai_provider import OpenAILLM
        return OpenAILLM(**kwargs)
    raise ValueError(f'Unknown provider {provider!r}. Add an adapter in assistant/providers/.')
