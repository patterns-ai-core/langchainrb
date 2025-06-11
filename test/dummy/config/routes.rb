Rails.application.routes.draw do
  mount Langchain::Engine => "/langchain"
end
