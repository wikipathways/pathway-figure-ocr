#session_id=$(curl -X POST --data-binary @examples/29968724.json https://www.ncbi.nlm.nih.gov/research/pubtator-api/annotations/annotate/submit/Gene)
#session_id=$(curl -X POST --data-binary @examples/29968724.PubTator https://www.ncbi.nlm.nih.gov/research/pubtator-api/annotations/annotate/submit/Gene)
#session_id=$(curl -X POST --data-binary @examples/20085714.PubTator https://www.ncbi.nlm.nih.gov/research/pubtator-api/annotations/annotate/submit/Gene)

session_id=$(curl -X POST --data-binary @examples/29968724fake.PubTator "https://www.ncbi.nlm.nih.gov/research/pubtator-api/annotations/annotate/submit/Gene")

echo "curl https://www.ncbi.nlm.nih.gov/research/pubtator-api/annotations/annotate/retrieve/$session_id"

sleep 120

curl https://www.ncbi.nlm.nih.gov/research/pubtator-api/annotations/annotate/retrieve/$session_id
