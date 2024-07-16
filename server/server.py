from typing import Any
from flask import Flask, request, jsonify, Response
from rich import print
import datetime
from elasticsearch import Elasticsearch
from langchain_elasticsearch import ElasticsearchStore
from langchain_huggingface import HuggingFaceEmbeddings
import sys
import os
from pathlib import Path
current_path = Path(__file__).parent.absolute()
sys.path.append(str(current_path.parent))
from config import cfg
from llm import llm_sort, scan_k_recent_msgs, llm_correlation_analysis
from collections import deque
import time
os.chdir(current_path)

elastic_online = False
napcat_online = False

try:
    ca_certs_path = os.path.join(current_path, "engines","elasticsearch","config","certs","http_ca.crt")
    es = Elasticsearch("https://localhost:9200",
                    ca_certs = ca_certs_path,
                    basic_auth = ["elastic", cfg["elastic_password"]],
                    )
    msg_vector_store = ElasticsearchStore(
            index_name = "test_qq_msg",
            embedding = HuggingFaceEmbeddings(),
            es_connection = es
        )
    elastic_online = True
except Exception as e:
    print(e)
    time.sleep(10)


    
app = Flask(__name__)
wait_list = deque()
keywords_dict = {}

@app.route('/get_msg', methods = ['POST'])
def get_msg() -> Response:
    """
    从请求中获取JSON数据，并处理消息数据。
    
    Args:
        无。
    
    Returns:
        Response: 返回一个字符串"ok"，表示消息处理成功。
    
    """
    global napcat_online
    napcat_online = True

    json_data = request.get_json()
    print(json_data)
    msg_data = request_process(json_data)

    if msg_data is not None:
        save_msg(msg_data)
        print(msg_data)
        wait_list.append(msg_data)
        while(len(wait_list) > 10):
            wait_list.popleft()
    return "ok"

@app.route('/recent_msg', methods = ['GET'])
def recent_msg() -> Response:
    """
    返回等待列表中的消息并清空列表。
    
    Args:
        无。
    
    Returns:
        Response: 包含等待列表中消息的 JSON 格式响应体。
    
    """
    global wait_list
    return_data = jsonify(list(wait_list))
    wait_list.clear()
    return return_data

@app.route('/monitor_keyword', methods = ['GET'])
def monitor_keyword() -> Response:
    """
    根据传入的关键词和索引，检查关键词是否存在于关键词字典中，并返回相应的状态。
    
    Args:
        无。
    
    Returns:
        Response: 包含 JSON 格式的响应体，其中 "status" 字段表示关键词监测结果的状态。
                   - 如果关键词已存在于关键词字典中，返回 {"status": "NG"}。
                   - 如果关键词不存在于关键词字典中，将其加入字典并返回 {"status": "OK"}。
    
    """
    keywords = request.args.get("keywords")
    keywords = keywords.split(",")
    print(keywords)
    msg = request.args.get("msg")
    res = llm_correlation_analysis(keywords, msg)
    return jsonify({"res": res})

@app.route('/check_status', methods = ['GET'])
def check_status() -> Response:
    """
    检查Napcat和Elastic服务的状态并返回相应字符串。
    
    Args:
        无。
    
    Returns:
        str: 返回一个字符串，表示当前的服务状态。
            - 如果Napcat不在线而Elastic在线，则返回"Elastic"。
            - 如果Napcat在线而Elastic不在线，则返回"Napcat"。
            - 如果两者都在线，则返回"Both"。
    
    """
    if (not napcat_online) and elastic_online:
        return "Elastic"
    elif napcat_online and (not elastic_online):
        return "Napcat"
    else:
        return "Both"

@app.route('/clear', methods = ['GET'])
def clear() -> Response:
    global keywords_dict
    keywords_dict.clear()
    return "ok"

@app.route('/similar_msg', methods = ['GET'])
def top_k_similar_msg() -> Response:
    """
    根据关键词查询最相似的k条消息并返回其元数据。
    
    Args:
        无。
    
    Returns:
        返回一个JSON对象，包含查询到的最相似的k条消息的元数据列表。
    
    HTTP参数说明:
    - k: int类型，表示要返回的最相似的消息数量。
    - keyword: str类型，表示用于查询相似消息的关键词（当method为默认时无需指定）。
    - start_date: str类型，可选参数，格式为"%Y-%m-%d-%H-%M-%S"，表示查询时间范围的起始时间。
    - end_date: str类型，可选参数，格式为"%Y-%m-%d-%H-%M-%S"，表示查询时间范围的结束时间。
    - nickname: str类型，可选参数，表示发送消息的昵称。
    - user_id: int类型，可选参数，表示发送消息的用户ID。
    - group_id: int类型，可选参数，表示发送消息的群组ID。
    - method: str类型，可选参数，表示查询方法，可选值为"basic"（基于向量相似度查询）、"llm"（基于大型语言模型排序）和默认方法（按时间顺序返回最近的k条消息）。
    - order: str类型，可选参数，表示排序方式，仅当method为默认方法时有效，可选值为"asc"（升序）和"desc"（降序），默认为"desc"。
    
    Returns (JSON):
    - 返回一个包含查询到的最相似的k条消息的元数据列表的JSON对象。
    """
    """
    根据关键词查询最相似的k条消息并返回其元数据。

    Returns:
        返回一个JSON对象，包含查询到的最相似的k条消息的元数据列表。
    """
    k = request.args.get("k")
    keyword = request.args.get("keyword", default = None)
    start_date = request.args.get("start_date", default = None)
    end_date = request.args.get("end_date", default = None)
    nickname = request.args.get("nickname", default = None)
    user_id = request.args.get("user_id", default = None)
    group_id = request.args.get("group_id", default = None)
    method = request.args.get("method", default = None)
    order = request.args.get("order", default = "desc")
    formatted_now = datetime.datetime.now()
    range_filter = {
        "range": {
            "metadata.time.keyword" : {
                "gte": "1992-01-01 00:00:00",
                "format": "yyyy-MM-dd hh:mm:ss"
            }
        },
    }
    filter = [range_filter]

    if start_date is not None:
        start_date = datetime.datetime.strptime(start_date, "%Y-%m-%d-%H-%M-%S").strftime("%Y-%m-%d %H:%M:%S")
        range_filter["range"]["metadata.time.keyword"]["gte"] = start_date
        

    if end_date is not None:
        end_date = datetime.datetime.strptime(end_date, "%Y-%m-%d-%H-%M-%S").strftime("%Y-%m-%d %H:%M:%S")
        range_filter["range"]["metadata.time.keyword"]["lte"] = end_date
    
    if nickname is not None:
        match_filter = {
            "match": {
            }
        }
        match_filter["match"]["metadata.sender.nickname.keyword"] = nickname
        filter.append(match_filter)
    
    if user_id is not None:
        match_filter = {
            "match": {
            }
        }
        match_filter["match"]["metadata.sender.user_id"] = int(user_id)
        filter.append(match_filter)

    if group_id is not None:
        match_filter = {
            "match": {
            }
        }
        match_filter["match"]["metadata.group_id"] = int(group_id)
        filter.append(match_filter)

    print(filter)
    if(method == "basic"):
        results = msg_vector_store.similarity_search(keyword, k = k, filter = filter)

        return_data = []
        for result in results:
            metadata, content = result.metadata, result.page_content
            print(metadata)
            return_data.append(metadata)
    elif(method == "llm"):
        return_data = llm_sort(es = es, keywords = keyword, k = int(k), filter = filter)
    else:
        k_recent_msgs = scan_k_recent_msgs(es, filter = filter, k = int(k), order=order)

        return_data = []
        for i in range(len(k_recent_msgs)):
            return_data.append(k_recent_msgs[i]["_source"]["metadata"])

    return jsonify(return_data)
    

def request_process(json_data: dict[Any]) -> "dict | None":
    """
    用于处理请求中的消息数据，返回处理后的数据字典。
    
    Args:
        - json_data (dict[Any]): 请求中的json
    
    Returns:
        dict: 处理后的数据字典，包含以下字段：\n
            - sender (str): 发送者ID，可能为None。
            - privacy (str): 消息隐私性，可能为"private"（私聊）或"group"（群聊），也可能为None。
            - msg_type (str): 消息类型，可能为"text"（文本）或"image"（图片），也可能为"other"（其他类型）或None。
            - content (str): 消息内容，根据type不同，可能为文本内容或图片URL，也可能为None。
            - group_id (str): 群聊ID，当privacy为"group"时有效，否则为None。
            - time (str): 消息时间，格式为'%Y-%m-%d %H:%M:%S'
    Raises:
        无特定异常类型抛出，但会在处理过程中捕获并打印所有异常。
    """
    return_data = {
        "sender": None,
        "privacy": None,
        "msg_type": None,
        "content": None,
        "group_id": None,
        "time": None
    }
    try:
        if json_data["post_type"] == 'message':
            # 判断消息类型, 忽略除消息外类型
            return_data["sender"] = json_data['sender']
            time = datetime.datetime.fromtimestamp(json_data['time']).strftime('%Y-%m-%d %H:%M:%S')
            return_data["time"] = time
            
            
            if json_data["message"][-1]["type"] == "text":
                # 文本消息
                return_data["msg_type"] = "text"
                return_data["content"] = json_data["message"][0]["data"]["text"]
            elif json_data["message"][-1]["type"] == "image":
                # 图片消息
                return_data["msg_type"] = "image"
                return_data["content"] = json_data["message"][0]["data"]["url"]
            else:
                # 其他消息, 暂不做处理
                return_data["msg_type"] = "other"

            if json_data["message_type"] == 'private':
                # 私聊消息
                return_data["privacy"] = "private"
                
            
            else:
                group_id = json_data["group_id"]
                return_data["privacy"] = "group"
                return_data["group_id"] = group_id
            return return_data
        else:
            return None
        
    except Exception as e:
        print(e)
        return None

def save_msg(msg_data: dict[Any]) -> None:
    """
    将文本消息保存到向量存储中。

    Args:
        - msg_data (dict[Any]): 包含消息数据的字典

    Returns:
        None
    """
    # 保存文本消息
    if msg_data["msg_type"] == "text":
        content = msg_data["content"]
        msg_vector_store.add_texts(texts = [content], metadatas=[msg_data])[0]
        


if __name__ == "__main__":
    print("START")
    app.run(port = 6155, debug = True)
    if(elastic_online == False):
        while(True):
            try:
                ca_certs_path = os.path.join(current_path, "engines","elasticsearch","config","certs","http_ca.crt")
                es = Elasticsearch("https://localhost:9200",
                                ca_certs = ca_certs_path,
                                basic_auth = ["elastic", cfg["elastic_password"]],
                                )
                msg_vector_store = ElasticsearchStore(
                        index_name = "test_qq_msg",
                        embedding = HuggingFaceEmbeddings(),
                        es_connection = es
                    )
                elastic_online = True
            except Exception as e:
                print(e)
                time.sleep(10)
            finally:
                break


