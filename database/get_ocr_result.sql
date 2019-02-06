-- need to run this afterwards:
-- cat /tmp/ocr_result.json | sed 's/""/QUOTEAR/g' | sed 's/"//g' | sed 's/QUOTEAR/"/g' | jq '.textAnnotations[0]/decription'
copy
(SELECT result FROM ocr_processors__figures WHERE figure_id = 8476)
to '/tmp/ocr_result.json' with csv;
