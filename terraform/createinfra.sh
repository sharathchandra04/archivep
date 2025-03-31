# cd vpct && terraform  init &&  cd ..
# cd sgt && terraform  init &&  cd ..
# cd rdst && terraform  init &&  cd ..
# cd s3t && terraform  init &&  cd ..
# cd dynamodbt && terraform  init &&  cd ..
# cd lambdat && terraform  init &&  cd ..
# cd amit && terraform  init &&  cd ..
# cd ec2setup && terraform  init &&  cd ..

ls
cd vpct && ./destroy.sh      && ./apply.sh &&  cd ..
cd sgt  && ./destroy.sh      && ./apply.sh &&  cd ..
cd rdst && ./destroy.sh      && ./apply.sh &&  cd ..
cd s3t  && ./destroy.sh      && ./apply.sh &&  cd ..
cd dynamodbt && ./destroy.sh && ./apply.sh &&  cd ..
cd lambdat   && ./destroy.sh && ./apply.sh &&  cd ..
cd amit      && ./destroy.sh && ./apply.sh &&  cd ..
cd ec2setupt && ./destroy.sh && ./apply.sh &&  cd ..