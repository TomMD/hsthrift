--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements. See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership. The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- License); you may not use this file except in compliance
-- with the License. You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied. See the License for the
-- specific language governing permissions and limitations
-- under the License.
--


module Thrift.Compiler.Pretty
  ( renderTypeError
  , renderTypeErrorPlain
  , renderType
  , ppHeader, ppName, ppType, ppText
  ) where

import Text.PrettyPrint hiding ((<>))
import Data.Some
import Data.Text (Text)
import qualified Data.Text as Text

import Thrift.Compiler.Parser
import Thrift.Compiler.Plugin
import Thrift.Compiler.Typechecker.Monad
import Thrift.Compiler.Types

renderType :: Typecheckable l => Type l t -> String
renderType = render . ppType

renderTypeError :: Typecheckable l => TypeError l -> String
renderTypeError = render . ppTypeError

renderTypeErrorPlain :: Typecheckable l => TypeError l -> String
renderTypeErrorPlain = render . ppTypeErrorPlain

ppTypeError :: Typecheckable l => TypeError l -> Doc
ppTypeError (TypeError loc msg) = "" $$ hang (ppHeader loc) 1 (ppErrorMsg msg)
ppTypeError EmptyInput = "" $$ red "Error: no input files specified"
ppTypeError (CyclicModules ms) =
  "" $$ hang (red "Error: cycle in modules:") 1
    (sep (punctuate "," (map (text . thriftPath) ms)))

ppTypeErrorPlain :: Typecheckable l => TypeError l -> Doc
ppTypeErrorPlain (TypeError loc msg) =
  ppHeaderPlain loc <+> ppErrorMsg msg
ppTypeErrorPlain EmptyInput = "Error: no input files specified"
ppTypeErrorPlain (CyclicModules ms) =
  "Error: cycle in modules:" <+>
    sep (punctuate "," (map (text . thriftPath) ms))

ppHeader :: Loc -> Doc
ppHeader loc = red (ppHeaderPlain loc)

ppHeaderPlain :: Loc -> Doc
ppHeaderPlain Loc{..} =
  hcat $ map (<> ":") [ text locFile, int locStartLine, int locStartCol ]

ppErrorMsg :: Typecheckable l => ErrorMsg l -> Doc
ppErrorMsg (CyclicTypes decls) =
 "cycle in types:" <+> sep (punctuate "," (foldr getName [] decls))
    where
      getName (D_Typedef Typedef{..}) ns = ppText tdName : ns
      getName (D_Struct Struct{..} )  ns = ppText structName : ns
      getName (D_Union Union{..})     ns = ppText unionName : ns
      getName (D_Enum Enum{..})       ns = ppText enumName : ns
      getName D_Const{}               ns = ns
      getName D_Service{}             ns = ns
ppErrorMsg (CyclicServices ss) =
  "cycle in service hierarchy:" <+> sep (punctuate "," (map getName ss))
    where
      getName Service{..} = quotes $ ppText serviceName
ppErrorMsg (UnknownType name)  = "unknown type" <+> quotes (ppName_ name)
ppErrorMsg (UnknownConst name) = "unknown constant" <+> quotes (ppName_ name)
ppErrorMsg (UnknownService name) = "unknown service" <+> quotes (ppName_ name)
ppErrorMsg (UnknownField name) = "unknown field" <+> quotes (ppText name)
ppErrorMsg (MissingField name) = "missing field" <+> quotes (ppText name)
ppErrorMsg (InvalidFieldId name fid) =
  hang "invalid field id:" 1 $
    "field" <+> quotes (ppText name) <+> "has id" <+> quotes (int fid) $$
    "field ids must be unique and non-zero"
ppErrorMsg (InvalidField val)  =
  hang "invalid field name:" 1 $
    "struct fields must be string literals" $$
    "got" <+> quotes (ppConst val)
ppErrorMsg (InvalidUnion name n) =
  hang ("invalid union literal for type" <+> (quotes (ppName name) <> ":")) 1 $
    "unions must contain exactly 1 field" $$
    "got" <+> int n <+> "fields"
ppErrorMsg (EmptyUnion name) =
  hang ("invalid union declaration" <+> (quotes (ppText name) <> ":")) 1 $
    "unions must contain at least one alternative" $$
    "try using an empty enum"
ppErrorMsg (InvalidThrows ty name) =
  hang ("invalid throws declaration" <+> (quotes (ppText name) <> ":")) 1 $
    "all fields in a throws clause must be exceptions" $$
    "but got type" <+> quotes (ppType ty)
ppErrorMsg (LiteralMismatch ty val) =
  hang "type mismatch:" 1 $
    "expected value of type" <+> quotes (ppType ty) $$
    "but got" <+> quotes (ppConst val)
ppErrorMsg (IdentMismatch expect actual name) =
  hang "type mismatch:" 1 $
    "expected value of type" <+> quotes (ppType expect) $$
    "but got identifier" <+> quotes (ppName_ name) <+>
      "of type" <+> quotes (ppType actual)
ppErrorMsg (AnnotationMismatch place ann) =
  hang "annotation mismatch:" 1 $
    "cannot use annotation" <+> quotes (ppAnnotation ann) $$
    "in" <+> ppPlacement place
ppErrorMsg (DuplicateName name) =
  "multiple definitions of" <+> quotes (ppText name)
ppErrorMsg (DuplicateEnumVal enum names val) =
  hang "duplicate enum value" 1 $
    "enum" <+> quotes (ppText enum) <+>
      "has multiple constructors with value" <+> quotes (int val) $$
    "constructors are" <+> hcat (map (quotes . ppText) names)

red :: Doc -> Doc
red doc = zeroWidthText "\ESC[31;1m" <> doc <> zeroWidthText "\ESC[0m"

ppPlacement :: Typecheckable l => AnnotationPlacement l -> Doc
ppPlacement (AnnType ty) = "type" <+> ppType ty
ppPlacement AnnField = "field"
ppPlacement AnnStruct = "struct"
ppPlacement AnnUnion = "union"
ppPlacement AnnTypedef = "typedef"
ppPlacement AnnEnum = "enum"
ppPlacement AnnPriority = "priority"

ppType :: Typecheckable l => Type l t -> Doc
ppType I8   = "byte"
ppType I16  = "i16"
ppType I32  = "i32"
ppType I64  = "i64"
ppType TDouble = "double"
ppType TFloat  = "float"
ppType TBool   = "bool"
ppType TText   = "string"
ppType TBytes  = "binary"
ppType (TSet u)     = hcat [ "set<", ppType u, ">" ]
ppType (THashSet u) = hcat [ "hash_set<", ppType u, ">" ]
ppType (TList u)    = hcat [ "list<", ppType u, ">" ]
ppType (TMap k v) = hcat [ "map<", ppType k, ", ", ppType v, ">" ]
ppType (THashMap k v) = hcat [ "hash_map<", ppType k, ", ", ppType v, ">" ]
ppType (TTypedef name _ _loc) = ppName name
ppType (TNewtype name _ _loc) = ppName name
ppType (TStruct name _loc)    = ppName name
ppType (TException name _loc) = ppName name
ppType (TUnion name _loc)     = ppName name
ppType (TEnum name _loc _)      = ppName name
ppType (TSpecial ty) = case backTranslateType ty of
  (This u, name) -> ppType u <+> parens (ppText name)

ppName :: Name -> Doc
ppName Name{..} = ppName_ sourceName

ppName_ :: Name_ s -> Doc
ppName_ (UName name) = text $ Text.unpack name
ppName_ (QName m name) =
    hcat [ ppText m, ".", ppText name ]

ppText :: Text -> Doc
ppText = text . Text.unpack

ppConst :: UntypedConst a -> Doc
ppConst (UntypedConst _ c) = ppConstVal c

ppConstVal :: ConstVal a -> Doc
ppConstVal (IntVal _ i)    = ppText i
ppConstVal (DoubleVal _ d) = ppText d
ppConstVal (StringVal s qt) = addQuotes $ text $ Text.unpack s
  where
    addQuotes = case qt of
      DoubleQuote -> doubleQuotes
      SingleQuote -> quotes
ppConstVal (IdVal x)     = text $ Text.unpack x
ppConstVal ListVal{..} =
  brackets $ sep $ punctuate "," $ map (ppConst . leElem) lvElems
ppConstVal MapVal{..} = braces $ sep $ punctuate "," $ map pp mvElems
  where
    pp ListElem{ leElem = MapPair{..} } =
      hsep [ ppConst mpKey, ":", ppConst mpVal ]
ppConstVal (BoolVal b)
  | b         = text "true"
  | otherwise = text "false"

ppAnnotation :: Annotation a -> Doc
ppAnnotation SimpleAnn{..} = parens $ ppText saTag
ppAnnotation ValueAnn{..} = parens $
  ppText vaTag <+> "=" <+>
  case vaVal of
    TextAnn txt _ -> doubleQuotes (ppText txt)
    IntAnn x _ -> int x