F5Run
---

Vim简单代码运行插件（使用:terminal）。

### 使用

在.vimrc中添加：

```vimscript
nnoremap <silent> <YOUR_KEY> :call f5#Run()<CR>
tnoremap <silent> <C-W><YOUR_KEY> <C-W>:call f5#Run()<CR>
```

其中`<YOUR_KEY>`换成需要的快捷键，比如`<F5>`。

### 可用函数：

|函数|描述|
|--|--|
|f5#Run| 运行当前窗口中的代码。如果在终端窗口内，则运行相关联的代码。 |

### 配置：

|变量|描述|取值|
|--|--|--|
|g:f5#pos|指定终端打开的位置，相对于源代码窗口。|right, left, top, bottom|