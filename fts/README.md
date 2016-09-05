# Full Text Search

Full Text Search (далее FTS) в PostgreSQL

Файлы словарей взяты из проекта tpro2009 10.02.2015

Актуальная версия setup.sql размещена в http://git.it.tender.pro/iac/pgm/src/master/sql/fts

## Настройка полнотекстового поиска

### 1. Файлы словарей

Для правильной настройки полнотекстового поиска необходимы файлы словарей:
 - russian.dict
 - russian.affix
 - english.dict
 - english.affix
 - russian_tpro_synonym_phrases.ths
 
Их нужно скорпировать в папку tsearch_data
(по умолчанию это каталог /usr/share/postgresql/9.3/tsearch_data/)

### 2. Настройка словарей

Скрипт настройки должен выполняться с правами владельца БД.
См [setup.sql](setup.sql)

### 3. Использование словарей

Название поисковой конфигурации зашивается в функцию public.const_search() и, если в настройках БД параметр default_text_search_config не совпадает с ее значением, в запросах надо использовать ее имя.


```
-- Далее необходимо создать индекс на таблице table_name.field_name на основе словаря
CREATE INDEX ON table_name USING gin (to_tsvector(const_search(), field_name));

-- Диагностика плана запроса: необходимо убедиться в том, что gin индексы на основе словарей russian_dict_thesaurus будут использованы

explain (analyse, verbose)
select * from ru_ru.product_data -- в этой таблице должно быть достаточно данных для того, чтобы оптимизатор мог выбрать сканирование индекса вместо seq scan-а
where to_tsvector(const_search(), name ) @@ to_tsquery(const_search(), plainto_tsquery( 'стальные листов' )::text )

"Bitmap Heap Scan on ru_ru.product_data  (cost=28.04..39.88 rows=3 width=229) (actual time=1.655..1.901 rows=1122 loops=1)"
"  Output: id, name, anno"
"  Recheck Cond: (to_tsvector(const_search(), product_data.name) @@ to_tsquery('iac_ru_en_dict'::regconfig, (plainto_tsquery('стальные листов'::text))::text))"
"  ->  Bitmap Index Scan on product_data_ru_en_name_idx  (cost=0.00..28.04 rows=3 width=0) (actual time=1.643..1.643 rows=1122 loops=1)"
"        Index Cond: (to_tsvector('iac_ru_en_dict'::regconfig, product_data.name) @@ to_tsquery('iac_ru_en_dict'::regconfig, (plainto_tsquery('стальные листов'::text))::text))"
"Total runtime: 2.044 ms"
```

### 3. Общая проверка правильности конфигурации всех словарей
```
SELECT 
       token
      ,dictionary
      ,lexemes
       FROM 
         ts_debug(const_search(),'words стальные листов листового остальные ксерокс existing operations')
       WHERE 
         lexemes IS NOT NULL
     ;

"words";"iac_en_dict";"{word}"
"стальные";"iac_ru_dict";"{стальной}"
"листов";"iac_ru_dict";"{лист}"
"листового";"iac_ru_dict";"{листовой}"
"остальные";"iac_ru_dict";"{остальной}"
"ксерокс";"iac_ru_dict_thesaurus";"{xerox}"
"existing";"iac_en_dict";"{existing,exist}"
"operations";"iac_en_dict";"{operate}"


SELECT to_tsvector(const_search(), 'дрель bosch с коррозионностойкий сверлом') @@ plainto_tsquery(const_search(), 'дрель бош нерж');
# true
 
SELECT to_tsvector(const_search(), 'бензопила husqvarna с нержавеющей цепью') @@ plainto_tsquery(const_search(), 'пила хускварна нерж');
# true

SELECT to_tsvector(const_search(), 'клапан запорный корозийностойкий') @@ plainto_tsquery(const_search(), 'вентиль нержавеющий');
# true
```
