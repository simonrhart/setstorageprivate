# sets the resource within the passed subscription Id to private access and private containers
subscriptionId=$1;
storageAccountName=$2;
echo "SubscriptionId to process: " $subscriptionId
echo "Storage account resource to process: " $storageAccountName

# select the subscription.
az account set -s $subscriptionId
 
echo 'Setting storage account:' $storageAccountName ' public access configuration to 'disabled''

# set public access to off at the account level.
az storage account update --name $storageAccountName --allow-blob-public-access false --output yaml

# now we iterate every container within this storage account and turn off anon access. First get key1 for the current storage account.
echo "Retrieving storage account key1 for storage account: " $storageAccountName
storageKeys=$(az storage account keys list --account-name $storageAccountName --query '[].value' -o json)
for key1 in $storageKeys  
do
   if [ ${#key1} -gt 8 ]; then
      echo $key1
      # remove double quotes from key
      key1=`sed -e 's/"//g' <<<"$key1"`
      # remove comma (from json)
      key1=`sed -e 's/,//g' <<<"$key1"`  
      echo 'Found key1: ' "${key1//'['}"  
      break
   fi
done

echo "Retrieving storage account containers for storage account: " $storageAccountName
storageContainers=$(az storage container list --account-key $key1 --account-name $storageAccountName --query '[].name')         

echo "Found the following storage container(s):"
for c in $storageContainers  
do 
     if [ ${#c} -gt 2 ]; then
        echo $c
     fi  
done

for storageContainer in $storageContainers  
do
    if [ ${#storageContainer} -gt 2 ]; then
       # remove double quotes from key
       storageContainer=`sed -e 's/"//g' <<<"$storageContainer"`
       # remove comma (from json)
       storageContainer=`sed -e 's/,//g' <<<"$storageContainer"`        
         
       echo "Setting storage container: " $storageContainer " public access to 'off' for storage account: " $storageAccountName
       az storage container set-permission --name $storageContainer --account-key $key1 --account-name $storageAccountName --public-access off --output yaml
    fi   
done
echo "Completed"

