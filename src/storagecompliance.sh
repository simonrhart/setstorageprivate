subscriptionId=$1;
echo "SubscriptionId to process: " $subscriptionId 
az account set -s $subscriptionId

#get a list of all storage account names as an array in this subscription.
echo "Retrieving collection of storage accounts..."
storageArray=$(az storage account list --query '[].name')

echo "Found the following storage accounts in subscription: " $subscriptionId
for i in $storageArray  
do 
  echo "${i//'['}"  
done

for storageAccountName in $storageArray  
do         
  # echo 'Turning off blob public access for storage account: ' $i   
  echo 'Cleaning JSON output query for record ' $storageAccountName
  # remove double quotes (from json)
  storageAccountName=`sed -e 's/"//g' <<<"$storageAccountName"`
  # remove comma (from json)
  storageAccountName=`sed -e 's/,//g' <<<"$storageAccountName"` 

  # we only need to check for brackets if processing json resultsets.  
  if [ $storageAccountName != '[' ] && [[ $storageAccountName != ']' ]]; then
     echo 'Setting storage account:' $storageAccountName ' public access configuration to 'disabled''

     # set public access to off at the account level.
     az storage account update --name $storageAccountName --allow-blob-public-access false --output yaml

     # now we iterate every container within this storage account and turn off anon access. First get key1 for the current storage account.
     echo "Retrieving storage account key1 for storage account: " $storageAccountName
     storageKeys=$(az storage account keys list --account-name $storageAccountName --query '[].value')
     for key1 in $storageKeys  
     do
         # remove double quotes from key
         key1=`sed -e 's/"//g' <<<"$key1"`
         # remove comma (from json)
         key1=`sed -e 's/,//g' <<<"$key1"`  
         echo 'Found key1: ' "${key1//'['}"  
         break
     done

     echo "Retrieving storage account containers for storage account: " $storageAccountName
     storageContainers=$(az storage container list --account-key $key1 --account-name $storageAccountName --query '[].name')         

     echo "Found the following storage container(s):"
     for c in $storageContainers  
     do 
        echo "${c//'['}"  
     done

     for storageContainer in $storageContainers  
     do
         # remove double quotes from key
         storageContainer=`sed -e 's/"//g' <<<"$storageContainer"`
         # remove comma (from json)
         storageContainer=`sed -e 's/,//g' <<<"$storageContainer"`        
         
         echo "Setting storage container: " $storageContainer " public access to 'off' for storage account: " $storageAccountName
         az storage container set-permission --name $storageContainer --account-key $key1 --account-name $storageAccountName --public-access off --output yaml
     done

  else
     # this will only execute if exporting the resultset as json
     echo 'Ignoring json record: ' $storageAccountName    
  fi 
done

echo "Completed"

