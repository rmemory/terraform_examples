export db_address=12.34.56.78
export db_port=8888
export server_port=5555

./user_data.sh

output=$(curl "http://localhost:$server_port")

if [[ $output == *"Hello world"* ]]; then 
  echo "Success"
else
  echo "Fail"
fi