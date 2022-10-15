module JellyDocs.Pages.Doc where

import Prelude

import Data.Either (Either(..))
import Data.HashMap (lookup)
import Data.Maybe (Maybe(..))
import Effect.Aff (launchAff_)
import Jelly.Data.Component (Component, el, signalC, text)
import Jelly.Data.Hooks (hooks)
import Jelly.Data.Prop ((:=))
import Jelly.Data.Signal (Signal)
import Jelly.Hooks.UseSignal (useSignal)
import Jelly.Router.Data.Router (useRouter)
import JellyDocs.Components.Markdown (markdownComponent)
import JellyDocs.Context (Context)
import JellyDocs.Contexts.Apis (useApis)
import JellyDocs.Data.Page (Page(..), pageToUrl)

docPage :: Signal String -> Component Context
docPage docIdSig = hooks do
  apis <- useApis

  let
    docSig = do
      statesSig <- apis.doc.statesSig
      docId <- docIdSig
      pure $ lookup docId statesSig

  -- fetch when doc data is not available
  useSignal $ docIdSig <#> \docId -> do
    launchAff_ $ void $ apis.doc.initialize docId
    mempty

  -- redirect to 404
  { replaceUrl } <- useRouter
  useSignal do
    doc <- docSig
    pure do
      case doc of
        Just (Left _) -> do
          replaceUrl $ pageToUrl PageNotFound
        _ -> pure unit
      mempty

  pure $ el "div" [ "class" := "py-10 px-20" ] $ signalC $ docSig <#> case _ of
    Just (Right doc) -> do
      el "div" [ "class" := "w-full flex justify-end" ] do
        el "a"
          [ "class" :=
              "block bg-slate-300 bg-opacity-0 text-teal-500 hover:text-teal-700 transition-colors rounded font-bold text-sm"
          , "href" := "github.com/yukikurage/jelly-docs/blob/master/docs/en/" <> doc.section <> "/" <> doc.id <>
              ".md"
          , "target" := "_blank"
          , "rel" := "noopener noreferrer"
          ]
          do
            text "Edit this page 📝"
      markdownComponent $ pure doc.content
    _ -> mempty
