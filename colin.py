# _*_coding:utf-8 _*_


import base64
from itertools import cycle


class StrCryption:
    """
    该类用于对字符串进行加解密使用, 初始化类传递一个加密的key
    加密之后的字符串将会是一个列表文件
    字符编码使用utf-8编码格式
    """

    def __init__(self, key):
        self.key = key
        self.bs64key = base64.b64encode(self.key.encode('utf-8')).decode('utf-8')

        self.keyord = list()
        for i in self.bs64key:
            self.keyord.append(ord(i))

    def encode(self, content):
        bs64str = base64.b64encode(content.encode('utf-8')).decode('utf-8')

        keyord = cycle(self.keyord)

        strord = list()
        for i in bs64str:
            strord.append(ord(i))

        cryord = list()
        for i, j in zip(strord, keyord):
            cryord.append(i ^ j)

        return cryord

    def decode(self, cryord):
        keyord = cycle(self.keyord)

        conord = list()
        for i, j in zip(cryord, keyord):
            conord.append(i ^ j)

        constr = str()
        for i in conord:
            constr = constr + chr(i)

        content = base64.b64decode(constr).decode('utf-8')
        return content


if __name__ == '__main__':
    print('date: 2021-01-27 \nauthor: colin \nEmail:740391452@qq.com')
