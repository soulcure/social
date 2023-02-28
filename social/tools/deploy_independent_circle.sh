echo "此脚本会修改项目文件，请注意不要提交这些自动修改的地方"

#cat >> pubspec.yaml<<EOF
#    - family: Noto
#      fonts:
#        - asset: assets/fonts/NotoSansSC-Regular.otf
#EOF

rm web/index.html
mv web/independent_circle.html web/index.html

fvm flutter build web -t lib/main_mobile_h5_circle.dart --web-renderer html

rm -rf build/circle
mv build/web build/circle

rsync -zvPrCc --delete ./build/circle root@129.204.153.68:/data/wwwroot/test/fanbook-web
# vuZtm1x9egvr
