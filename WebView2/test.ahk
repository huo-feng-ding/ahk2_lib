;  WebView2 相关代码来自 https://github.com/thqby/ahk2_lib   函数的使用来 https://www.autohotkey.com/boards/viewtopic.php?f=83&t=95666&sid=b34d71aba1f7912d5075bbd29945efe4&start=40
; ImagePut 相关代码来自 https://github.com/iseahound/ImagePut
; 两个相结合可以实现窗口切换的功能，ahk和webview2之间可以通过脚本来互相通信调用； ImagePut 主要是将程序的icon图标转成base64编码给webview2，然后在页面中展示  

#Include WebView2.ahk
#Include ImagePut.ahk

class SyncHandler extends WebView2.Handler {
	__New(cb := 0) {
		this.obj := SyncHandler.CompletedEventHandler()
		this.obj.cb := cb
		super.__New(this.obj, 3)
	}
	wait() {
		o := this.obj
		while !o.status
			Sleep(10)
		o.status := 0, Sleep(100)
	}

	class CompletedEventHandler {
		status := 0, cb := 0
		call(handler, args*) {
			if this.cb
				(this.cb)(args)
			this.status := 1
		}
	}
}


Path := WinGetProcessPath("ahk_exe code.exe")
handle := LoadPicture(Path ,"w32")
imgbase:=ImagePutBase64(handle)

main := Gui('+Resize')
main.OnEvent('Close', (*) => (wvc := wv := 0))
main.OnEvent('Size', gui_size)
main.Show(Format('w{} h{}', A_ScreenWidth * 0.6, A_ScreenHeight * 0.6))

;nav_sync := SyncHandler()
exec_sync := SyncHandler((args) => OutputDebug(StrGet(args[2])))

wvc := WebView2.create(main.Hwnd)
wv := wvc.CoreWebView2
;wv.add_NavigationCompleted(nav_sync)
wv.Navigate('file:///' A_ScriptDir '/test.html')
wv.AddHostObjectToScript('ahk', {str:'str from ahk',func:MsgBox})
;wv.ExecuteScript('window.mytest="wang"', WebView2.Handler(handler))
;nav_sync.wait()
;wv.OpenDevToolsWindow()
script := 'window.mytest="data:img/jpg;base64,' imgbase '";'
wv.AddScriptToExecuteOnDocumentCreated('window.addEventListener("load",(event)=>{ ' script 'init() })', exec_sync)
 exec_sync.wait()

handler(handlerptr, result, success) {
	if (!success)
		MsgBox 'PrintToPdf fail`nerr: ' result ' '  handlerptr
}

;resize wvc with main gui window
gui_size(GuiObj, MinMax, Width, Height) {
    if (MinMax != -1) {
        try wvc.Fill()
    }
}

getIconBase64FromProcess(WinTitle){
    Path := WinGetProcessPath(WinTitle)
    handle := LoadPicture(Path ,"w32")
    imgbase:=ImagePutBase64(handle)
}

f1::main.Hide()
f2::{
    imgbase:=getIconBase64FromProcess("ahk_exe chrome.exe")
    script := 'window.mytest="data:img/jpg;base64,' imgbase '";init();'
    wv.ExecuteScript(script, WebView2.Handler(handler))
    ;nav_sync.wait()
    main.Show()
}