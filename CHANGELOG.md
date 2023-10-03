## [Unreleased]

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
