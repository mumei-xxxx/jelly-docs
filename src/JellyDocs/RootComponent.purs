module JellyDocs.RootComponent where

import Prelude

import Data.Array (find)
import Data.Either (Either(..))
import Data.Foldable (traverse_)
import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import Jelly.Component (class Component, doctypeHtml, text, textSig)
import Jelly.Element as JE
import Jelly.Prop (on, onMount, (:=))
import JellyDocs.Capability.Api (class Api, useDocsApi, useSectionsApi)
import JellyDocs.Capability.Nav (class Nav, useCurrentPage)
import JellyDocs.Component.Drawer (drawerComponent)
import JellyDocs.Component.Logo (logoComponent)
import JellyDocs.Component.Sidebar (sidebarComponent)
import JellyDocs.Data.Page (Page(..))
import JellyDocs.Page.Doc (docPage)
import JellyDocs.Page.NotFound (notFoundPage)
import JellyDocs.Page.Top (topPage)
import JellyDocs.Twemoji (emojiProp)
import JellyDocs.Utils (scrollToTop)
import Signal (Signal, newState, readSignal, writeChannel)
import Signal.Hooks (class MonadHooks, newStateEq, useAff, useEffect_, useHooks_)
import Web.HTML.Event.EventTypes (click)

rootComponent :: forall m. Nav m => Api m => Component m => m Unit
rootComponent = do
  doctypeHtml
  JE.html [ "lang" := "en", "class" := "font-Lato text-slate-800" ] do
    headComponent
    bodyComponent

useTitleSig :: forall m. Nav m => MonadHooks m => Api m => m (Signal String)
useTitleSig = do
  currentPage <- useCurrentPage
  docsApi <- useDocsApi
  docsSig <- useAff $ pure docsApi
  pure do
    docs <- docsSig
    cp <- currentPage
    case cp of
      PageTop -> pure "Jelly : Reactive-based UI framework for PureScript"
      PageDoc docId
        | Just (Right ds) <- docs, Just { title } <- find (\{ id } -> docId == id) ds -> pure $ title <> " - Jelly"
      _ -> pure "Not Found - Jelly"

headComponent :: forall m. Nav m => Api m => Component m => m Unit
headComponent = JE.head' do
  JE.title' do
    textSig =<< useTitleSig

  JE.script
    [ "src" := "/index.js" ]
    $ pure unit

  JE.link [ "rel" := "stylesheet", "href" := "/index.css" ]

  JE.meta [ "name" := "viewport", "content" := "width=device-width,initial-scale=1.0" ]

  JE.link
    [ "rel" := "preconnect"
    , "href" := "https://fonts.gstatic.com"
    , "crossorigin" := true
    ]
  JE.link
    [ "rel" := "preload"
    , "as" := "style"
    , "href" :=
        "https://fonts.googleapis.com/css2?family=Lato:wght@400;700;900&family=Montserrat:wght@900&family=Source+Code+Pro&display=swap"
    ]
  JE.link
    [ "rel" := "stylesheet"
    , "href" :=
        "https://fonts.googleapis.com/css2?family=Lato:wght@400;700;900&family=Montserrat:wght@900&family=Source+Code+Pro&display=swap"
    , "media" := "print"
    , "onload" := "this.media='all'"
    ]

  JE.link
    [ "rel" := "preload"
    , "as" := "style"
    , "href" :=
        "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.10/styles/atom-one-light.min.css"
    ]
  JE.link
    [ "rel" := "stylesheet"
    , "href" := "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.10/styles/atom-one-light.min.css"
    , "media" := "print"
    , "onload" := "this.media='all'"
    ]

  JE.meta
    [ "name" := "description"
    , "content" := "Documentation for PureScript Jelly, a framework for building reactive web applications."
    ]

bodyComponent :: forall m. Nav m => Api m => Component m => m Unit
bodyComponent = do
  isSidebarOpenSig /\ isSidebarOpenChannel <- newStateEq false
  currentPage <- useCurrentPage
  scrollElSig /\ scrollElChannel <- newState Nothing

  -- | Hide sidebar when temporary url is changed
  useEffect_ $ currentPage $> do
    writeChannel isSidebarOpenChannel false
    scrollEl <- readSignal scrollElSig
    traverse_ scrollToTop scrollEl

  sectionsApi <- useSectionsApi
  sectionsSig <- useAff $ pure sectionsApi

  JE.body [ "class" := "fixed left-0 top-0 flex flex-row items-start h-window w-screen" ] do
    let
      sidebar = sidebarComponent do
        sections <- sectionsSig
        pure case sections of
          Just (Right scts) -> scts
          _ -> []
    JE.div
      [ "class" := "block lg:hidden absolute left-0 top-0 w-full backdrop-blur bg-white bg-opacity-60" ]
      do
        JE.button
          [ "class" :=
              "p-1 m-3 text-lg rounded border-slate-300 border-opacity-50 border hover:bg-slate-300 hover:bg-opacity-30 hover:active:bg-opacity-20 transition-all"
          , emojiProp
          , on click \_ -> writeChannel isSidebarOpenChannel true
          ]
          do
            text "📒"
        JE.div [ "class" := "w-full h-[1px] bg-slate-300 bg-opacity-50" ] $ pure unit
        JE.div [ "class" := "absolute left-1/2 -translate-x-1/2 top-1/2 -translate-y-1/2" ] logoComponent
        drawerComponent { onClose: writeChannel isSidebarOpenChannel false, openSig: isSidebarOpenSig } sidebar
    JE.div [ "class" := "h-full w-fit hidden lg:block overflow-auto" ] do
      sidebar
    JE.div [ "class" := "h-full w-[1px] bg-slate-300 bg-opacity-50 hidden lg:block" ] $ pure unit
    JE.div [ "class" := "flex-1 overflow-auto h-full flex justify-center", onMount (Just >>> writeChannel scrollElChannel) ]
      do
        JE.main [ "class" := "w-full xl:w-[60rem] pt-14 min-h-0 lg:pt-0" ] $ useHooks_ do
          cp <- currentPage
          pure case cp of
            PageTop -> topPage
            PageDoc docId -> docPage $ pure docId
            PageNotFound -> notFoundPage
