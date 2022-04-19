import datetime
import json
import os
from pathlib import Path
import re
import requests
import sys
from pprint import pprint
import time
from unidecode import unidecode

repo_dir = Path("./")

args = sys.argv[1:]

supported_concepts = set(["chemical", "disease"])

if (not args) or (not args[0] in supported_concepts):
    if args[0] == "-f":
        print("It appears this is running in a notebook.")
    
    print(f"Please specify a concept {list(supported_concepts)}:")
    concept = input()
else:
    concept = args[0]

if not concept in supported_concepts:
    raise Exception(
f"""concept '{concept}' is not supported.
Please choose from supported concepts: {list(supported_concepts)}
""")

data_dir = repo_dir.joinpath(f"pubtator-{concept}")
if not data_dir.exists():
    data_dir.mkdir()

pathway_likelihood_score_threshhold = 0.5
pfocr_ids = set()
for p in repo_dir.joinpath("gcv-automl").glob("*.json"):
    pfocr_id = str(p.with_suffix(".jpg").name)
    with p.open("r") as f:
        gcv_automl_data = json.load(f)
        pathway_likelihood_score = gcv_automl_data["classification"]["score"]
        if pathway_likelihood_score >= pathway_likelihood_score_threshhold:
            pfocr_ids.add(pfocr_id)

processesed_pfocr_ids = set()
for p in data_dir.glob("*.json"):
    pfocr_id = str(p.with_suffix(".jpg").name)
    processesed_pfocr_ids.add(pfocr_id)

remaining_pfocr_ids = pfocr_ids - processesed_pfocr_ids
#remaining_pfocr_ids = list(pfocr_ids - processesed_pfocr_ids)[:500]

ocr_text_by_pfocr_id = dict()
for p in repo_dir.joinpath("gcv-ocr").glob("*.json"):
    pfocr_id = str(p.with_suffix(".jpg").name)
    with p.open("r") as f:
        gcv_ocr_data = json.load(f)
        if not gcv_ocr_data:
            print(f"No OCR data for {pfocr_id}")
            continue
        if pfocr_id in remaining_pfocr_ids:
            ocr_text = gcv_ocr_data[0]["description"]
            ocr_text_by_pfocr_id[pfocr_id] = ocr_text


max_article_length = 200e3

# chr(31) is for the ASCII field separator character
# https://en.wikipedia.org/wiki/C0_and_C1_control_codes#Field_separators
separator = " " + chr(31) + " "

open_paren_re = re.compile("\(")
close_paren_re = re.compile("\)")
side_metabolite_re = re.compile("[HCONSP]|[^a-z]", re.I)

title_re = re.compile("(^.+?)\|(t)\|(.*)")
abstract_re = re.compile("(.+?)\|(a)\|(.*)")
space_only_re = re.compile("^\s*$")
denotation_re = re.compile("(.+?)\t(.+?)\t(.+?)\t(.+?)\t(.+)")

error_message_codes_by_error_message = {
    "[Warning] : The Session number does not exist.": "nonexistent_session",
    '{"detail": "We have trouble processing your query"}': "trouble_processing",
}

def create_pubtator_session(request_body, bioconcept):
    # submit request
    r = requests.post(
        f"https://www.ncbi.nlm.nih.gov/research/pubtator-api/annotations/annotate/submit/{bioconcept}",
        data=request_body.encode("utf-8"),
    )
    result = {"status_code": r.status_code}
    if r.status_code != 200:
        print("[Error]: HTTP code " + str(r.status_code))
    else:
        session_number = r.text
        result["session_number"] = session_number
        print(
            "Thanks for your submission. The session number is: "
            + session_number
            + "\n"
        )

    return result

# Collect responses to the requests made earlier to the PubTator API:
def retrieve_pubtator_session_results(session_number, iteration=0, delay=20):
    res = requests.get(
        f"https://www.ncbi.nlm.nih.gov/research/pubtator-api/annotations/annotate/retrieve/{session_number}"
    )

    res_text = res.text
    if res_text == "[Warning] : The Result is not ready.\n":
        time.sleep(delay)
        return retrieve_pubtator_session_results(session_number, iteration=iteration + 1, delay=delay * 1.5)
    elif res_text == '{"detail": "We have trouble processing your query"}':
        raise Warning(
            f"Warning: PubTator had trouble processing query for {session_number}"
        )
    else:
        return res_text


sessions = []
# We send batched requests to PubTator, meaning we send multiple figures per
# request. We accumulate the figure ocr text onto the request body until the
# batch reaches the size limit or we run out of figures. If the batch reaches
# the size limit, we send that request and start a new one.
batched_request_body = ""

for pfocr_id, figure_ocr_text in ocr_text_by_pfocr_id.items():
    if figure_ocr_text:
        text_chunks = []
        for text_chunk in unidecode(
            figure_ocr_text.replace("\n", separator)
            .replace("\t", separator)
            .replace("  ", separator)
            .replace("|", separator)
        ).split(separator):
            # Ignore words like this:
            # H
            # CH20
            # 721-2
            # --..>
            if len(side_metabolite_re.sub("", text_chunk)) == 0:
                continue

            open_paren_count = len(open_paren_re.findall(text_chunk))
            close_paren_count = len(close_paren_re.findall(text_chunk))
            if open_paren_count > close_paren_count:
                # if the text_chunk is "(Pyruvate", we need to balance the parens, because
                # the PubTator API won't return anything if parens are unbalanced.
                text_chunk += " " + ")" * (open_paren_count - close_paren_count) + " "
                # TODO: is there any way we could get a false positive by adding close parens?
                # should we add an extra open paren first to avoid false positives?
                # text_chunk += (" (" + ")" * (open_paren_count - close_paren_count + 1) + " ")
            text_chunks.append(text_chunk)

        text = separator.join(text_chunks)

        # Note: the extra empty line at the bottom is required
        current_figure_request_body = f"""{pfocr_id}|t|{text}
{pfocr_id}|a|

"""

        if (
            len(batched_request_body + current_figure_request_body) > max_article_length
        ):
            sessions.append(create_pubtator_session(batched_request_body, concept))
            batched_request_body = ""

        batched_request_body += current_figure_request_body

# if the batched_request_body never reached max_article_length or
# if the final figure didn't fit into the last session,
# we need to process it here
if (
    len(batched_request_body) > 0
):
    sessions.append(create_pubtator_session(batched_request_body, concept))
    batched_request_body = ""

print(f"finished submitting PubTator {concept} requests")    
    
# Estimating total time required until results available
# (copied from PubTator docs)
initial_delay = len(sessions) * 200 + 250
preprocessing_time = 200
processing_time = max_article_length / 800
estimated_total_time = initial_delay + preprocessing_time + processing_time
ready = datetime.datetime.now() + datetime.timedelta(seconds=estimated_total_time)
print(f"Estimated total time to complete: {str(int(estimated_total_time))} seconds")
print(f"Estimated time when complete: {ready.strftime('%c')}")
#max_wait_seconds = 60 * 5
max_wait_seconds = 60 * 60 * 2
wait_seconds = min((ready - datetime.datetime.now()).total_seconds(), max_wait_seconds)
if wait_seconds > 0:
    time.sleep(wait_seconds)

denotations_by_pfocr_id = {}
errors = []

for session in sessions:
    pubtator_response = retrieve_pubtator_session_results(session["session_number"])

    pfocr_id = None
    denotations = []

    lines = pubtator_response.splitlines()
    for i, line in enumerate(lines):
        context = "\n".join(lines[max(0, i - 1):i + 2])
        # Does this line include an error message? Check by running through the
        # error messages we've observed to see whether one of them is in this
        # line. If yes, excise the error from the line and keep going.
        for (
            error_message,
            error_message_code,
        ) in error_message_codes_by_error_message.items():
            error_message_len = len(error_message)
            if line[0:error_message_len] == error_message:
                errors.append(error_message_code)
                line = line[error_message_len:]

        # an empty line indicates the end of lines for current figure
        if space_only_re.match(line):
            if len(denotations) > 0:
                print(f"no hits for {pfocr_id}\n")

            # reset
            pfocr_id = None
            denotations = []

            continue

        title_match = title_re.match(line)
        if title_match:
            if pfocr_id or len(denotations) > 0:
                raise Exception(
f"""pfocr_id and/or denotations weren't reset before title line!
Was there no empty line before the title line?
{context}
""")

            pfocr_id = title_match.group(1)
            denotations_by_pfocr_id[pfocr_id] = denotations

            continue

        abstract_match = abstract_re.match(line)
        if abstract_match:
            source_id = abstract_match.group(1)
            if len(denotations) > 0:
                raise Exception(
f"""denotations weren't reset before abstract line!
Was there no title line before the abstract line?
{context}
""")
            elif (not source_id) or (
                source_id != pfocr_id
            ):
                print(
f"""source_id {source_id} != pfocr_id {pfocr_id}!
Was there no title line before the abstract line?
{context}
""")

                # reset
                pfocr_id = None
                denotations = []

                continue

                #raise Exception(
                #    f"source_id {source_id} should match pfocr_id {pfocr_id}! Was the expected preceeding title line missing?"
                #)

            continue

        denotation_match = denotation_re.match(line)
        if denotation_match:
            source_id = denotation_match.group(1)
            if (not pfocr_id) or (
                source_id != pfocr_id
            ):
                raise Exception(
f"""source_id {source_id} should match pfocr_id {pfocr_id}!
Was the expected title line or abstract line missing?
{context}
""")

            word = denotation_match.group(4)
            obj = denotation_match.group(5)

            denotation = {"word": word}
            denotations.append(denotation)

            word_type, obj_separator, word_identifier = obj.partition("\t")

            if word_type:
                denotation["type"] = word_type
            else:
                print(f"{pfocr_id} missing type. expected 'type\\tidentifier' but got '{obj}'")

            if word_identifier:
                denotation["identifier"] = word_identifier
            else:
                print(f"{pfocr_id} missing identifier. expected 'type\\tidentifier' but got '{obj}'")

            continue

        raise Exception(
f"""Error: Unknown line type.
{context}
""")

print(f"finished retrieving PubTator {concept} results")
        
for pfocr_id, denotations in denotations_by_pfocr_id.items():
    with open(data_dir.joinpath(pfocr_id).with_suffix(".json"), "w") as f:
        json.dump(denotations, f)
