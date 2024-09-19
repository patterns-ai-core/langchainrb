## [Unreleased]

## [0.16.0] - 2024-09-19
- Remove `Langchain::Thread` class as it was not needed.
- Support `cohere` provider for `Langchain::LLM::AwsBedrock#embed`

## [0.15.6] - 2024-09-16
- Throw an error when `Langchain::Assistant#add_message_callback` is not a callable proc.
- Resetting instructions on Langchain::Assistant with Google Gemini no longer throws an error.
- Add Meta models support for AWS Bedrock LLM

## [0.15.5] - 2024-09-10 🇧🇦
- Fix for Langchain::Prompt::PromptTemplate supporting nested JSON data
- Require common libs at top-level
- Add `add_message_callback` to `Langchain::Assistant` constructor to invoke an optional function when any message is added to the conversation
- Adding Assistant syntactic sugar with #run! and #add_message_and_run!

## [0.15.4] - 2024-08-30
- Improve the Langchain::Tool::Database tool
- Allow explictly setting tool_choice on the Assistant instance
- Add support for bulk embedding in Ollama
- `Langchain::Assistant` works with `Langchain::LLM::MistralAI` llm
- Fix Langchain::LLM::Azure not applying full default_options

## [0.15.3] - 2024-08-27
- Fix OpenAI#embed when text-embedding-ada-002 is used

## [0.15.2] - 2024-08-23
- Add Assistant#add_messages() method and fix Assistant#messages= method

## [0.15.1] - 2024-08-19
- Drop `to_bool` gem in favour of custom util class
- Drop `colorize` which is GPL-licensed in favour of `rainbow`
- Improve Langchain::Tool::Weather tool

## [0.15.0] - 2024-08-14
- Fix Langchain::Assistant when llm is Anthropic
- Fix GoogleGemini#chat method
- Langchain::LLM::Weaviate initializer does not require api_key anymore
- [BREAKING] Langchain::LLM::OpenAI#chat() uses `gpt-4o-mini` by default instead of `gpt-3.5-turbo` previously.
- [BREAKING] Assistant works with a number of open-source models via Ollama.
- [BREAKING] Introduce new `Langchain::ToolDefinition` module to define tools. This replaces the previous reliance on subclassing from `Langchain::Tool::Base`.

## [0.14.0] - 2024-07-12
- Removed TokenLength validators
- Assistant works with a Mistral LLM now
- Assistant keeps track of tokens used
- Misc fixes and improvements

## [0.13.5] - 2024-07-01
- Add Milvus#remove_texts() method
- Langchain::Assistant has a `state` now
- Misc fixes and improvements

## [0.13.4] - 2024-06-16
- Fix Chroma#remove_texts() method
- Fix NewsRetriever Tool returning non UTF-8 characters
- Misc fixes and improvements

## [0.13.3] - 2024-06-03
- New 🛠️  `Langchain::Tool::Tavily` to execute search (better than the GoogleSearch tool)
- Remove `activesupport` dependency
- Misc fixes and improvements

## [0.13.2] - 2024-05-20
- New `Langchain::LLM::GoogleGemini#embed()` method
- `Langchain::Assistant` works with `Langchain::LLM::Anthropic` llm
- New XLS file processor
- Fixes and improvements

## [0.13.1] - 2024-05-14
- Better error handling for `Langchain::LLM::GoogleVertexAI`

## [0.13.0] - 2024-05-14
- New 🛠️ `Langchain::Tool::NewsRetriever` tool to fetch news via newsapi.org
- Langchain::Assistant works with `Langchain::LLM::GoogleVertexAI` and `Langchain::LLM::GoogleGemini` llms
- [BREAKING] Introduce new `Langchain::Messages::Base` abstraction

## [0.12.1] - 2024-05-13
- Langchain::LLM::Ollama now uses `llama3` by default
- Langchain::LLM::Anthropic#complete() now uses `claude-2.1` by default
- Updated with new OpenAI models, including `gpt-4o`
- New `Langchain::LLM::Cohere#chat()` method.
- Introducing `UnifiedParameters` to unify parameters across LLM classes

## [0.12.0] - 2024-04-22
- [BREAKING] Rename `dimension` parameter to `dimensions` everywhere

## [0.11.4] - 2024-04-19
- New `Langchain::LLM::AWSBedrock#chat()` to wrap Bedrock Claude requests
- New `Langchain::LLM::OllamaResponse#total_tokens()` method

## [0.11.3] - 2024-04-16
- New `Langchain::Processors::Pptx` to parse .pptx files
- New `Langchain::LLM::Anthropic#chat()` support
- Misc fixes

## [0.11.2]
- New `Langchain::Assistant#clear_thread!` and `Langchain::Assistant#instructions=` methods

## [0.11.1]
- Langchain::Tool::Vectorsearch that wraps Langchain::Vectorsearch::* classes. This allows the Assistant to call the tool and inject data from vector DBs.

## [0.11.0]
- Delete previously deprecated `Langchain::Agent::ReActAgent` and `Langchain::Agent::SQLQueryAgent` classes
- New `Langchain::Agent::FileSystem` tool that can read files, write to files, and list the contents of a directory

## [0.10.3]
- Bump dependencies
- Ollama#complete fix
- Misc fixes

## [0.10.2]
- New Langchain::LLM::Mistral
- Drop Ruby 3.0 support
- Fixes Zeitwerk::NameError

## [0.10.1] - GEM VERSION YANKED

## [0.10.0]
- Delete `Langchain::Conversation` class

## [0.9.5]
- Now using OpenAI's "text-embedding-3-small" model to generate embeddings
- Added `remove_texts(ids:)` method to Qdrant and Chroma
- Add Ruby 3.3 support

## [0.9.4]
- New `Ollama#summarize()` method
- Improved README
- Fixes + specs

## [0.9.3]
- Add EML processor
- Tools can support multiple-methods
- Bump gems and bug fixes

## [0.9.2]
- Fix vectorsearch#ask methods
- Bump cohere-ruby gem

## [0.9.1]
- Add support for new OpenAI models
- Add Ollama#chat method
- Fix and refactor of `Langchain::LLM::Ollama`, responses can now be streamed.

## [0.9.0]
- Introducing new `Langchain::Assistant` that will be replacing `Langchain::Conversation` and `Langchain::Agent`s.
- `Langchain::Conversation` is deprecated.

## [0.8.2]
- Introducing new `Langchain::Chunker::Markdown` chunker (thanks @spikex)
- Fixes

## [0.8.1]
- Support for Epsilla vector DB
- Fully functioning Google Vertex AI LLM
- Bug fixes

## [0.8.0]
- [BREAKING] Updated llama_cpp.rb to 0.9.4. The model file format used by the underlying llama.cpp library has changed to GGUF. llama.cpp ships with scripts to convert existing files and GGUF format models can be downloaded from HuggingFace.
- Introducing Langchain::LLM::GoogleVertexAi LLM provider

## [0.7.5] - 2023-11-13
- Fixes

## [0.7.4] - 2023-11-10
- AWS Bedrock is available as an LLM provider. Available models from AI21, Cohere, AWS, and Anthropic.

## [0.7.3] - 2023-11-08
- LLM response passes through the context in RAG cases
- Fix gpt-4 token length validation

## [0.7.2] - 2023-11-02
- Azure OpenAI LLM support

## [0.7.1] - 2023-10-26
- Ragas evals tool to evaluate Retrieval Augmented Generation (RAG) pipelines

## [0.7.0] - 2023-10-22
- BREAKING: Moving Rails-specific code to `langchainrb_rails` gem

## [0.6.19] - 2023-10-18
- Elasticsearch vector search support
- Fix `lib/langchain/railtie.rb` not being loaded with the gem

## [0.6.18] - 2023-10-16
- Introduce `Langchain::LLM::Response`` object
- Introduce `Langchain::Chunk` object
- Add the ask() method to the Langchain::ActiveRecord::Hooks

## [0.6.17] - 2023-10-10
- Bump weaviate and chroma-db deps
- `Langchain::Chunker::Semantic` chunker
- Re-structure Conversations class
- Bug fixes

## [0.6.16] - 2023-10-02
- HyDE-style similarity search
- `Langchain::Chunker::Sentence` chunker
- Bug fixes

## [0.6.15] - 2023-09-22
- Bump weaviate-ruby gem version
- Ollama support

## [0.6.14] - 2023-09-11
- Add `find` method to `Langchain::Vectorsearch::Qdrant`
- Enhance Google search output
- Raise ApiError when OpenAI returns an error
- Update OpenAI `complete` method to use chat completion api
  - Deprecate legacy completion models. See https://platform.openai.com/docs/deprecations/2023-07-06-gpt-and-embeddings

## [0.6.13] - 2023-08-23
- Add `k:` parameter to all `ask()` vector search methods
- Bump Faraday to 2.x

## [0.6.12] - 2023-08-13

## [0.6.11] - 2023-08-08

## [0.6.10] - 2023-08-01
- 🗣️ LLMs
  - Introducing Anthropic support

## [0.6.9] - 2023-07-29

## [0.6.8] - 2023-07-21

## [0.6.7] - 2023-07-19
- Support for OpenAI functions
- Streaming vectorsearch ask() responses

## [0.6.6] - 2023-07-13
- Langchain::Chunker::RecursiveText
- Fixes

## [0.6.5] - 2023-07-06
- 🗣️ LLMs
  - Introducing Llama.cpp support
- Langchain::OutputParsers::OutputFixingParser to wrap a Langchain::OutputParser and handle invalid response

## [0.6.4] - 2023-07-01
- Fix `Langchain::Vectorsearch::Qdrant#add_texts()`
- Introduce `ConversationMemory`
- Allow loading multiple files from a directory
- Add `get_default_schema()`, `create_default_schema()`, `destroy_default_schema()` missing methods to `Langchain::Vectorsearch::*` classes

## [0.6.3] - 2023-06-25
- Add #destroy_default_schema() to Langchain::Vectorsearch::* classes

## [0.6.2] - 2023-06-25
- Qdrant, Chroma, and Pinecone are supported by ActiveRecord hooks

## [0.6.1] - 2023-06-24
- Adding support to hook vectorsearch into ActiveRecord models

## [0.6.0] - 2023-06-22
- [BREAKING] Rename `ChainOfThoughtAgent` to `ReActAgent`
- Implement A21 token validator
- Add `Langchain::OutputParsers`

## [0.5.7] - 2023-06-19
- Developer can modify models used when initiliazing `Langchain::LLM::*` clients
- Improvements to the `SQLQueryAgent` and the database tool

## [0.5.6] - 2023-06-18
- If used with OpenAI, Langchain::Conversation responses can now be streamed.
- Improved logging
- Langchain::Tool::SerpApi has been renamed to Langchain::Tool::GoogleSearch
- JSON prompt templates have been converted to YAML
- Langchain::Chunker::Text is introduced to provide simple text chunking functionality
- Misc fixes and improvements

## [0.5.5] - 2023-06-12
- [BREAKING] Rename `Langchain::Chat` to `Langchain::Conversation`
- 🛠️ Tools
  - Introducing `Langchain::Tool::Weather`, a tool that calls Open Weather API to retrieve the current weather

## [0.5.4] - 2023-06-10
- 🔍 Vectorsearch
  - Introducing support for HNSWlib
- Improved and new `Langchain::Chat` interface that persists chat history in memory

## [0.5.3] - 2023-06-09
- 🗣️ LLMs
  - Chat message history support for Langchain::LLM::GooglePalm and Langchain::LLM::OpenAI

## [0.5.2] - 2023-06-07
- 🗣️ LLMs
  - Auto-calculate the max_tokens: setting to be passed on to OpenAI

## [0.5.1] - 2023-06-06
- 🛠️ Tools
  - Modified Tool usage. Agents now accept Tools instances instead of Tool strings.

## [0.5.0] - 2023-06-05
- [BREAKING] LLMs are now passed as objects to Vectorsearch classes instead of `llm: :name, llm_api_key:` previously
- 📋 Prompts
  - YAML prompt templates are now supported
- 🚚 Loaders
  - Introduce `Langchain::Processors::Xlsx` to parse .xlsx files

## [0.4.2] - 2023-06-03
- 🗣️ LLMs
  - Introducing support for AI21
- Better docs generation
- Refactors

## [0.4.1] - 2023-06-02
- Beautiful colored log messages
- 🛠️ Tools
  - Introducing `Langchain::Tool::RubyCodeInterpreter`, a tool executes sandboxed Ruby code

## [0.4.0] - 2023-06-01
- [BREAKING] Everything is namespaced under `Langchain::` now
- Pgvector similarity search uses the cosine distance by default now
- OpenAI token length validation using tiktoken_ruby

## [0.3.15] - 2023-05-30
- Drop Ruby 2.7 support. It had reached EOD.
- Bump pgvector-ruby to 0.2
- 🚚 Loaders
  - Support for options and block to be passed to CSV processor

## [0.3.14] - 2023-05-28
- 🔍 Vectorsearch
  - Not relying on Weaviate modules anymore
  - Adding missing specs for Qdrant and Milvus classes
- 🚚 Loaders
  - Add Langchain::Data result object for data loaders
- 🗣️ LLMs
  - Add `summarize()` method to the LLMs

## [0.3.13] - 2023-05-26
- 🔍 Vectorsearch
  - Pgvector support
- 🚚 Loaders
  - CSV loader
  - JSON loader
  - JSONL loader

## [0.3.12] - 2023-05-25
- 🔍 Vectorsearch
  - Introduce namespace support for Pinecone
- 🚚 Loaders
  - Loaders overhaul

## [0.3.11] - 2023-05-23
- 🗣️ LLMs
  - Introducing support for Google PaLM (Pathways Language Model)
- Bug fixes and improvements

## [0.3.10] - 2023-05-19
- 🗣️ LLMs
  - Introducing support for Replicate.com

## [0.3.9] - 2023-05-19
- 🚚 Loaders
  - Introduce `Loaders::Docx` to parse .docx files

## [0.3.8] - 2023-05-19
- 🔍 Vectorsearch
  - Introduce support for Chroma DB

- 🚚 Loaders
  - Bug fix `Loaders::Text` to only parse .txt files

## [0.3.7] - 2023-05-19
- 🚚 Loaders
  - Introduce `Loaders::Text` to parse .txt files
  - Introduce `Loaders::PDF` to parse .pdf files

## [0.3.6] - 2023-05-17
- 🗣️ LLMs
  - Bump `hugging-face` gem version

## [0.3.5] - 2023-05-16
- Bug fixes

## [0.3.4] - 2023-05-16
- 🗣️ LLMs
  - Introducing support for HuggingFace

## [0.3.3] - 2023-05-16
- Dependencies are now optionally loaded and required at runtime
- Start using `standardrb` for linting
- Use the Ruby logger

## [0.3.2] - 2023-05-15
- 🤖 Agents
  - Fix Chain of Thought prompt loader

## [0.3.1] - 2023-05-12
- 🛠️ Tools
  - Introducing `Tool::Wikipedia`, a tool that looks up Wikipedia entries

## [0.3.0] - 2023-05-12
- 🤖 Agents
  - Introducing `Agent::ChainOfThoughtAgent`, a semi-autonomous bot that uses Tools to retrieve additional information in order to make best-effort informed replies to user's questions.
- 🛠️ Tools
  - Introducing `Tool::Calculator` tool that solves mathematical expressions.
  - Introducing `Tool::Search` tool that executes Google Searches.

## [0.2.0] - 2023-05-09
- 📋 Prompt Templating
  - Ability to create prompt templates and save them to JSON files
  - Default `Prompt::FewShotPromptTemplate`
  - New examples added to `examples/`

## [0.1.4] - 2023-05-02
- Backfilling missing specs

## [0.1.3] - 2023-05-01
- Initial release
