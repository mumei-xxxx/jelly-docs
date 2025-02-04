module Example.Hooks where

import Prelude

import Data.Tuple.Nested ((/\))
import Effect.Class.Console (log)
import Jelly.Component (Component, hooks, switch, text)
import Jelly.Element as JE
import Jelly.Hooks (class MonadHooks, useCleaner, useStateEq)
import Jelly.Prop (on)
import Jelly.Signal (ifSignal, writeChannel)
import Web.HTML.Event.EventTypes (click)

hooksExample :: forall m. MonadHooks m => Component m
hooksExample = hooks do
  log "Mounted"

  useCleaner do
    log "Unmounted"

  pure $ text "This is Hooks"

hooksExampleWrapper :: forall m. MonadHooks m => Component m
hooksExampleWrapper = hooks do
  isMountedSig /\ isMountedChannel <- useStateEq true

  pure do
    JE.button [ on click \_ -> writeChannel isMountedChannel true ] $ text "Mount"
    JE.button [ on click \_ -> writeChannel isMountedChannel false ] $ text "Unmount"
    switch $ ifSignal isMountedSig
      do JE.div' hooksExample
      do JE.div' $ text "Unmounted"
