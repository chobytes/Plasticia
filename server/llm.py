from langchain_community.llms.moonshot import Moonshot
from langchain.prompts import PromptTemplate
import json
import sys
import os
from elasticsearch.helpers import scan
from ast import literal_eval
from pathlib import Path
current_path = Path(__file__).parent.absolute()
sys.path.append(str(current_path.parent))
from config import cfg
os.chdir(current_path)


os.environ["MOONSHOT_API_KEY"] = cfg["moonshot_api_key"]

llm = Moonshot()

filter_prompt_template = PromptTemplate(
    input_variables=["keywords", "k", "msg_list"],
    template="""
    # 任务：信息筛选
    输入信息为一个包含多个信息的列表，列表中每一项为一个字典。
    字典中键为"text"的为信息，请仔细阅读; 字典中键为"index"的为序号，在筛选时请忽视。
    请根据关键字“{keywords}”对这些字典中的信息进行筛选，返回的{k}条最相关的字典，若你认为真正相关且有意义的信息少于{k}条，可以返回少于{k}条的信息。
    返回结果应为一个列表，其中包含这些字典。请确保列表中的信息按照与关键字的相关度从高到低排序。
    
    # 输入格式：List[Dict[str, Any]]
    # 输出格式：List[Dict[str, Any]]
    
    # 提示：
    请在处理文本时注意以下几点：
    1. 忽略与关键字无关的信息。
    2. 优先选择包含关键字且信息内容丰富的文本。
    3. 如果有多条信息与关键字相关度相近，请选择信息质量更高的文本。
    4. 只应返回列表，不要包含任何其他字符!

    以下为输入，请开始筛选信息。
    {msg_list}
    """
)

correlation_prompt_template = PromptTemplate(
    input_variables=["keywords", "msg"],
    template="""
    # 任务：相关性分析
    输入信息包括一个关键字列表和一条消息。
    请逐个分析关键字列表中的关键字和这条消息的相关性。
    返回一个元素为各个关键字与这条消息是否相关的列表。
    
    # 输出格式：List[Bool]
    
    # 提示：
    请在处理时注意以下几点：
    1. 列表元素为True表示关键字与消息相关，为False表示关键字与消息不相关。
    2. 在分析一个关键字和消息的相关性时不要考虑其他关键字
    3. 列表元素个数应与关键字列表中的关键字个数相同。
    4. 只应返回列表，不要包含任何其他字符!

    以下为关键字列表：
    {keywords}

    以下为消息：
    {msg}
    """
)


def scan_k_recent_msgs(es, filter, k = 100, order = "desc"):
    """
    扫描最近k条符合条件的消息。
    
    Args:
        es: Elasticsearch客户端对象。
        filter: 字典类型，用于筛选消息的查询条件。
        k: int类型，需要获取的消息数量，默认为100。
        order: str类型，排序方式，可选值为"desc"（降序）和"asc"（升序），默认为"desc"。
    
    Returns:
        list类型，包含k条符合条件的消息，每条消息为字典类型。
    
    """
    search_query = {
        "sort": [
            {"metadata.time.keyword": {"order": "desc"}}
        ],
        "query": {
            "bool":{
                "filter": filter
            }
        }
    }

    recent_docs = scan(
    client=es,
    query=search_query,
    index="test_qq_msg",
    preserve_order=True
    )

    if order == "desc":
        k_recent_msgs = list(recent_docs)[:k]
    else:
        k_recent_msgs = list(recent_docs)[-k:][::-1]
    return k_recent_msgs

def llm_sort(es, keywords, k, filter):
    
    # 出于对api用量的考虑,只将最近的100条信息作为输入
    k_recent_msgs = scan_k_recent_msgs(es, filter = filter, k = 100)
    k_recent_msgs_to_llm = []
    for i in range(len(k_recent_msgs)):
        msg = {
            "text": k_recent_msgs[i]["_source"]["text"],
            "index": i,
        }
        k_recent_msgs_to_llm.append(msg)
    inputs = filter_prompt_template.format(keywords=keywords, k=k, msg_list=k_recent_msgs_to_llm)
    output = llm.invoke(inputs)

    return_data = []
    try:
        output_list = literal_eval(output)
        for msg in output_list:
            return_data.append(k_recent_msgs[int(msg["index"])]["_source"]["metadata"])
    except Exception as e:
        print(e)
    
    print(output)
    return return_data

def llm_correlation_analysis(keywords, msg):
    inputs = correlation_prompt_template.format(keywords=keywords, msg=msg)
    output = llm.invoke(inputs)
    print(output)
    try:
        output_list = literal_eval(output)
    except Exception as e:
        print(e)

    return output_list