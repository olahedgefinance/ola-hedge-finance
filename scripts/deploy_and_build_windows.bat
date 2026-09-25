cd ..
cd budget

start cmd.exe /k flutter build appbundle --flavor production --release
start cmd.exe /k flutter build apk --flavor production --release
