module JellyDocs.Page.NotFound where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Jelly.Component (class Component)
import Jelly.Element as JE
import Jelly.Prop ((:=))
import JellyDocs.Capability.Api (class Api, useNotFoundApi)
import JellyDocs.Component.Markdown (markdownComponent)
import Signal.Hooks (useAff, useHooks_)

notFoundPage :: forall m. Api m => Component m => m Unit
notFoundPage = do
  notFoundApi <- useNotFoundApi

  notFoundSig <- useAff $ pure notFoundApi

  JE.div [ "class" := "px-4 py-10 lg:px-10" ] $ useHooks_ do
    notFound <- notFoundSig
    pure case notFound of
      Just (Right md) -> markdownComponent $ pure md
      _ -> pure unit
