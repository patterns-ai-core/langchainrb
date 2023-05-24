## [Unreleased]

## [0.3.13] - 2023-05-24
- 🔍 Vectorsearch
  - Introduce custom metadata support for Pinecone

## [0.3.12] - 2023-05-22
- 🔍 Vectorsearch
  - Introduce namespace support for Pinecone

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
