-- need to run this afterwards:
-- cat /tmp/ocr_result.json | sed 's/""/QUOTEAR/g' | sed 's/"//g' | sed 's/QUOTEAR/"/g' | jq '.fullTextAnnotation.text'
copy
(SELECT result FROM ocr_processors__figures)
to '/tmp/ocr_result.json' with csv;
