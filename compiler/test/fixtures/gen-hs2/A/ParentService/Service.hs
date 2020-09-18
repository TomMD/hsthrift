-----------------------------------------------------------------
-- Autogenerated by Thrift
--
-- DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
--  @generated
-----------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE BangPatterns #-}
{-# OPTIONS_GHC -fno-warn-unused-imports#-}
{-# OPTIONS_GHC -fno-warn-overlapping-patterns#-}
{-# OPTIONS_GHC -fno-warn-incomplete-patterns#-}
{-# LANGUAGE GADTs #-}
module A.ParentService.Service
       (ParentServiceCommand(..), reqName', reqParser', respWriter',
        onewayFunctions')
       where
import qualified A.Types as Types
import qualified B.Types as B
import qualified Control.Exception as Exception
import qualified Control.Monad.ST.Trans as ST
import qualified Control.Monad.Trans.Class as Trans
import qualified Data.ByteString.Builder as Builder
import qualified Data.Default as Default
import qualified Data.HashMap.Strict as HashMap
import qualified Data.Int as Int
import qualified Data.Proxy as Proxy
import qualified Data.Text as Text
import qualified Prelude as Prelude
import qualified Thrift.Binary.Parser as Parser
import qualified Thrift.Codegen as Thrift
import qualified Thrift.Processor as Thrift
import qualified Thrift.Protocol.ApplicationException.Types
       as Thrift
import Control.Applicative ((<*), (*>))
import Data.Monoid ((<>))
import Prelude ((<$>), (<*>), (++), (.), (==))

data ParentServiceCommand a where

instance Thrift.Processor ParentServiceCommand where
  reqName = reqName'
  reqParser = reqParser'
  respWriter = respWriter'
  onewayFns _ = onewayFunctions'

reqName' :: ParentServiceCommand a -> Text.Text
reqName' _ = "unknown function"

reqParser' ::
             Thrift.Protocol p =>
             Proxy.Proxy p ->
               Text.Text -> Parser.Parser (Thrift.Some ParentServiceCommand)
reqParser' _ funName
  = Prelude.fail ("unknown function call: " ++ Text.unpack funName)

respWriter' ::
              Thrift.Protocol p =>
              Proxy.Proxy p ->
                Int.Int32 ->
                  ParentServiceCommand a ->
                    Prelude.Either Exception.SomeException a ->
                      (Builder.Builder,
                       Prelude.Maybe (Exception.SomeException, Thrift.Blame))
respWriter' _ = Prelude.fail ("unknown function")

onewayFunctions' :: [Text.Text]
onewayFunctions' = []