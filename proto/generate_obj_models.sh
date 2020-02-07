#!/bin/bash

#Скрипт позволяет генерировать новые Proto-модели.
#Особенности:
# - Использует верную версию proto-компилятора.
# - Автоматически генерирует модели на основе всех .proto файлов в папке Contracts
# - Дает подсказку для добавления списка сгенерированных моделей в .h файл модуля, т.к. это необходимо для совместимости Objective-C и Swift.

PROTO_FILES="$(ls Contracts | grep proto)"


echo "Use contracts:"
echo $PROTO_FILES
echo

protoc --objc_out=Generated \
       --proto_path Contracts
       $PROTO_FILES

echo "// Copy that to your module header file:"
echo

ls -1 Contracts | sed -e 

#protoc --objc_out=. msg.proto
#protoc --plugin=/usr/local/bin/protoc-gen-objc Message.proto --objc_out="./"


