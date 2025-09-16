Rails.application.routes.draw do
  mount LangChain::Engine => "/langchain"
end
