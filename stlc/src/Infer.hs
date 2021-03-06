{-# LANGUAGE LambdaCase #-}

module Infer (infer) where

import qualified Env as E
import Types

type Env = E.Env Ident Typ

infer :: Env -> Term -> Either TypError Typ
infer env = \case
  TmTrue -> return TyBool
  TmFalse -> return TyBool
  TmUnit -> return TyUnit
  TmInt {} -> return TyInt
  TmVar name ->
    case E.lookup name env of
      Just typ -> return typ
      Nothing -> Left (TyUnboundVar name)
  TmAbs param typ body -> do
    let env' = E.extend param typ env
    bodyTyp <- infer env' body
    return (TyArrow typ bodyTyp)
  TmApp funct argument -> do
    functTyp <- infer env funct
    argumentTyp <- infer env argument
    case functTyp of
      (TyArrow paramTyp bodyTyp) ->
        if paramTyp == argumentTyp
          then return bodyTyp
          else Left (TyMismatch paramTyp argumentTyp)
      _ -> Left (TyExpectedFunction functTyp)
  TmIf pred conseq alt -> do
    predTyp <- infer env pred
    conseqTyp <- infer env conseq
    altTyp <- infer env alt
    case predTyp of
      TyBool ->
        if conseqTyp /= altTyp
          then Left (TyMismatch conseqTyp altTyp)
          else return conseqTyp
      _ -> Left (TyMismatch predTyp TyBool)
