关于XG推送证书验证工具的使用说明
1.工具支持DER、P12、PEM格式的推送证书的验证
2.发布环境的推送证书是收不到推送的，因为只有当你的APP在发布之后才能收到，这是APNS决定的
3.信鸽推送目前要求开发者上传的是PEM格式的证书，本工具可以将你从keychain中导出的P12格式的证书，在验证的时候，直接在P12同一文件夹下，为你生成信鸽使用的PEM格式的证书，请测试的时候查看
4.验证工具需要您提供XGSDK为你返回的Token，你要显示的消息(message),选择您的推送证书，如果是P12的，密码是需要的，验证证书的有效性，请留意工具的提示信息

#########################################################
@2016/08/16
1.增加XG推送服务器选项，
2.XG推送的参数都是必须得，QQ号是与AccessID关联的

#########################################################
@2016/10/08
1.XG服务支持P12格式推送证书
2.推送消息增加了时间戳
3.优化了使用体验

#########################################################
@2016/11/04
1.修正使用P12证书推送的bug
2.增加了创建证书的提示信息

#########################################################
@2016/11/16
1.修正bug
2.添加信鸽测试服务器选项

#########################################################
@2016/12/13
1.bug修正
2.删除XG服务证书上传的逻辑
3.修正内部开发网无法连接APNS的超长等待导致的假死问题

#########################################################
@2016/12/21
1.升级Swift3.0，Xcode8