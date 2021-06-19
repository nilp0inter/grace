{-| This module stores the `Monotype` type representing monomorphic types and
    utilites for operating on `Monotype`s
-}
module Grace.Monotype
    ( -- * Types
      Monotype(..)
    , Record(..)
    , Row(..)
    , Union(..)
    , Variant(..)
    ) where

import Data.String (IsString(..))
import Data.Text (Text)
import Data.Text.Prettyprint.Doc (Doc, Pretty(..))
import Grace.Existential (Existential)

-- $setup
--
-- >>> import qualified Grace.Monotype as Monotype

-- | A monomorphic type
data Monotype
    = Variable Text
    -- ^ Type variable
    --
    -- >>> pretty (Variable "a")
    -- a
    | Unsolved (Existential Monotype)
    -- ^ A placeholder variable whose type has not yet been inferred
    --
    -- >>> pretty (Unsolved 0)
    -- a?
    | Function Monotype Monotype
    -- ^ Function type
    --
    -- >>> pretty (Function "a" "b")
    -- a -> b
    | List Monotype
    -- ^ List type
    --
    -- >>> pretty (List "a")
    -- List a
    | Record Record
    -- ^ Record type
    --
    -- >>> pretty (Record (Fields [("x", "X"), ("y", "Y")] Monotype.EmptyRow))
    -- { x : X, y : Y }
    -- >>> pretty (Record (Fields [("x", "X"), ("y", "Y")] (Monotype.UnsolvedRow 0)))
    -- { x : X, y : Y | a? }
    | Union Union
    -- ^ Union type
    --
    -- >>> pretty (Union (Alternatives [("x", "X"), ("y", "Y")] Monotype.EmptyVariant))
    -- < x : X, y : Y >
    -- >>> pretty (Union (Alternatives [("x", "X"), ("y", "Y")] (Monotype.UnsolvedVariant 0)))
    -- < x : X, y : Y | a? >
    | Bool
    -- ^ Boolean type
    --
    -- >>> pretty Bool
    -- Bool
    | Natural
    -- ^ Natural number type
    --
    -- >>> pretty Natural
    -- Natural
    | Text
    -- ^ Text type
    --
    -- >>> pretty Text
    -- Text
    deriving stock (Eq, Show)

instance IsString Monotype where
    fromString string = Variable (fromString string)

instance Pretty Monotype where
    pretty = prettyMonotype

-- | A monomorphic record type
data Record = Fields [(Text, Monotype)] Row
    deriving stock (Eq, Show)

data Row
    = EmptyRow
    | UnsolvedRow (Existential Record)
    | VariableRow Text
    deriving stock (Eq, Ord, Show)

-- | A monomorphic union type
data Union = Alternatives [(Text, Monotype)] Variant
    deriving stock (Eq, Show)

data Variant
    = EmptyVariant
    | UnsolvedVariant (Existential Union)
    | VariableVariant Text
    deriving stock (Eq, Ord, Show)

prettyMonotype :: Monotype -> Doc a
prettyMonotype (Function _A _B) =
    prettyApplicationType _A <> " -> " <> prettyMonotype _B
prettyMonotype other =
    prettyApplicationType other

prettyApplicationType :: Monotype -> Doc a
prettyApplicationType (List _A) = "List " <> prettyPrimitiveType _A
prettyApplicationType  other    =  prettyPrimitiveType other

prettyPrimitiveType :: Monotype -> Doc a
prettyPrimitiveType (Variable α) =
    pretty α
prettyPrimitiveType (Unsolved α) =
    pretty α <> "?"
prettyPrimitiveType (Record r) =
    prettyRecordType r
prettyPrimitiveType (Union u) =
    prettyUnionType u
prettyPrimitiveType Bool =
    "Bool"
prettyPrimitiveType Natural =
    "Natural"
prettyPrimitiveType Text =
    "Text"
prettyPrimitiveType other =
    "(" <> prettyMonotype other <> ")"

prettyRecordType :: Record -> Doc a
prettyRecordType (Fields [] EmptyRow) =
    "{ }"
prettyRecordType (Fields [] (UnsolvedRow ρ)) =
    "{ " <> pretty ρ <> "? }"
prettyRecordType (Fields [] (VariableRow ρ)) =
    "{ " <> pretty ρ <> " }"
prettyRecordType (Fields ((key₀, type₀) : keyTypes) row) =
        "{ "
    <>  pretty key₀
    <>  " : "
    <>  prettyMonotype type₀
    <>  foldMap prettyKeyType keyTypes
    <>  case row of
            EmptyRow      -> " }"
            UnsolvedRow ρ -> " | " <> pretty ρ <> "? }"
            VariableRow ρ -> " | " <> pretty ρ <> " }"

prettyUnionType :: Union -> Doc a
prettyUnionType (Alternatives [] EmptyVariant) =
    "< >"
prettyUnionType (Alternatives [] (UnsolvedVariant ρ)) =
    "< " <> pretty ρ <> "?  >"
prettyUnionType (Alternatives [] (VariableVariant ρ)) =
    "< " <> pretty ρ <> "  >"
prettyUnionType (Alternatives ((key₀, type₀) : keyTypes) row) =
        "< "
    <>  pretty key₀
    <>  " : "
    <>  prettyMonotype type₀
    <>  foldMap prettyKeyType keyTypes
    <>  case row of
            EmptyVariant      -> " >"
            UnsolvedVariant ρ -> " | " <> pretty ρ <> "? >"
            VariableVariant ρ -> " | " <> pretty ρ <> " >"

prettyKeyType :: (Text, Monotype) -> Doc a
prettyKeyType (key, monotype) =
    ", " <> pretty key <> " : " <> prettyMonotype monotype
