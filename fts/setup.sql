/*
  Настройка FTS
*/
ROLLBACK;
BEGIN;

  drop TEXT SEARCH DICTIONARY IF EXISTS russian_dict_thesaurus cascade;
  drop TEXT SEARCH DICTIONARY IF EXISTS russian_dict cascade;
  drop TEXT SEARCH DICTIONARY IF EXISTS english_dict cascade;

  -- Тезаурус (словарь фраз-синонимов) ТПро
  CREATE TEXT SEARCH DICTIONARY public.russian_dict_thesaurus (
    Template =   thesaurus
  , DictFile =   russian_tpro_synonym_phrases
  , Dictionary = russian_stem
  );

  -- Морфологический словарь (русский)
  CREATE TEXT SEARCH DICTIONARY public.russian_dict (
    Template = ispell
  , DictFile = russian
  , AffFile = russian
  , StopWords = russian
  );

  -- Морфологический словарь (английский)
  CREATE TEXT SEARCH DICTIONARY public.english_dict (
    Template = ispell
  , DictFile = english
  , AffFile = english
  , StopWords = english
  );

  -- Порядок применения словарей

  -- удаляется при каскадном удалении словарей только если они используются
  DROP TEXT SEARCH CONFIGURATION IF EXISTS public.ru_en cascade;

  CREATE TEXT SEARCH CONFIGURATION public.ru_en(copy = english);

  ALTER TEXT SEARCH CONFIGURATION ru_en
    ALTER MAPPING FOR asciihword, asciiword, hword_asciipart
    WITH
      russian_dict_thesaurus		-- тезаурус (словарь фраз-синонимов)
    , english_dict			-- морфологический словарь английского языка
    , english_stem			-- системный словарь английского
  ;
  ALTER TEXT SEARCH CONFIGURATION ru_en
    ALTER MAPPING FOR hword, hword_part, word
    WITH
      russian_dict_thesaurus		-- тезаурус (словарь фраз-синонимов)
    , russian_dict			-- морфологический словарь русского языка
    , russian_stem			-- системный словарь русского
  ;

  CREATE OR REPLACE FUNCTION public.const_search() RETURNS regconfig IMMUTABLE LANGUAGE 'sql' AS
  $_$ SELECT 'ru_en'::regconfig $_$;
  COMMENT ON FUNCTION public.const_search() IS 'Имя схемы FTS по умолчанию';

COMMIT;
