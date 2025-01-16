﻿B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
'#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private DB As MiniORM
	Private DBConnector As DatabaseConnector
	Private lblTitle As B4XView
	Private lblBack As B4XView
	Private clvRecord As CustomListView
	Private btnEdit As B4XView
	Private btnDelete As B4XView
	Private btnNew As B4XView
	Private lblName As B4XView
	Private lblCategory As B4XView
	Private lblCode As B4XView
	Private lblPrice As B4XView
	Private lblStatus As B4XView
	Private PrefDialog1 As PreferencesDialog
	Private PrefDialog2 As PreferencesDialog
	Private PrefDialog3 As PreferencesDialog
	Dim Viewing As String
	Dim CategoryId As Int
	Dim Category() As Category
	Dim const COLOR_RED As Int = -65536			'ignore
	Dim const COLOR_BLUE As Int = -16776961		'ignore
	Dim const COLOR_MAGENTA As Int = -65281		'ignore
	Type Category (Id As Int, Name As String)
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
End Sub

Private Sub DBEngine As String
	Return DBConnector.DBEngine
End Sub

Private Sub DBOpen As SQL
	Return DBConnector.DBOpen
End Sub

Private Sub DBClose
	DBConnector.DBClose
End Sub

Public Sub ConfigureDatabase
	Dim con As Conn
	con.Initialize
	con.DBType = "SQLite"
	con.DBFile = "MiniORM.db"
	
	#If B4J
	con.DBDir = File.DirApp
	'xui.SetDataFolder(con.DBName)
	'con.DBDir = File.Combine(xui.DefaultFolder, con.DBDir)
	#Else
	con.DBDir = xui.DefaultFolder 
	#End If

	#If B4J
	'con.DBType = "MySQL"
	'con.DBName = "miniorm"
	'con.DbHost = "localhost"
	'con.User = "root"
	'con.Password = "password"
	'con.DriverClass = "com.mysql.cj.jdbc.Driver"
	'con.JdbcUrl = "jdbc:mysql://{DbHost}:{DbPort}/{DbName}?characterEncoding=utf8&useSSL=False"
	#End If

	Try
		DBConnector.Initialize(con)
		'Wait For (DBConnector.DBExist) Complete (DBFound As Boolean)
		Dim DBFound As Boolean = DBConnector.DBExist
		If DBFound Then
			LogColor($"${con.DBType} database found!"$, COLOR_BLUE)
			DB.Initialize(DBOpen, DBEngine)
			'DB.ShowExtraLogs = True
			GetCategories
		Else
			LogColor($"${con.DBType} database not found!"$, COLOR_RED)
			CreateDatabase
		End If
	Catch
		Log(LastException.Message)
		LogColor("Error checking database!", COLOR_RED)
		Log("Application is terminated.")
		#If B4J
		ExitApplication
		#End If
	End Try
End Sub

Private Sub CreateDatabase
	LogColor("Creating database...", COLOR_MAGENTA)
	Wait For (DBConnector.DBCreate) Complete (Success As Boolean)
	If Not(Success) Then
		Log("Database creation failed!")
		Return
	End If
	
	Dim MDB As MiniORM
	MDB.Initialize(DBOpen, DBEngine)
	'MDB.ShowExtraLogs = True
	MDB.UseTimestamps = True
	'MDB.ExecuteAfterCreate = True
	'MDB.ExecuteAfterInsert = True
	MDB.AddAfterCreate = True
	MDB.AddAfterInsert = True
	
	MDB.Table = "tbl_categories"
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "category_name")))
	MDB.Create
	
	MDB.Columns = Array("category_name")
	MDB.Insert2(Array("Hardwares"))
	MDB.Insert2(Array("Toys"))
	
	' set table name
	MDB.Table = "tbl_products"
	 ' add column to table (Method 1)
	Dim col1 As ORMColumn
	col1.ColumnName = "category_id"
	col1.ColumnType = MDB.INTEGER
	col1.DefaultValue = ""
	MDB.Columns.Add(col1)
	' add column to table (Method 2)
	MDB.Columns.Add(MDB.CreateORMColumn("product_code", MDB.VARCHAR, "12", "", "", True, True, False))
	' add column to table (Method 3) - more simpler
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "product_name")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "product_price", "Type": MDB.DECIMAL, "Size": "10,2", "Default": 0.0)))
	' add a foreign key to category table
	MDB.Foreign("category_id", "id", "tbl_categories", "", "")
	MDB.Create
	
	MDB.Columns = Array("category_id", "product_code", "product_name", "product_price")
	' add a row (Method 1)
	MDB.Parameters = Array As String(2, "T001", "Teddy Bear", 99.9)
	MDB.Insert
	' add a row (Method 2)
	MDB.Insert2(Array(1, "H001", "Hammer", 15.75))
	MDB.Insert2(Array(2, "T002", "Optimus Prime", 1000))
	
	Wait For (MDB.ExecuteBatch) Complete (Success As Boolean)
	If Success Then
		LogColor("Database is created successfully!", COLOR_BLUE)
	Else
		LogColor("Database creation failed!", COLOR_RED)
		Log(LastException)
	End If
	MDB.Close
	DB.Initialize(DBOpen, DBEngine)
	GetCategories
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")
	B4XPages.SetTitle(Me, "MiniORM")
	'#If B4J
	'CallSubDelayed3(Me, "SetScrollPaneBackgroundColor", clvRecord, xui.Color_Transparent)
	'#End If
	ConfigureDatabase
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	If xui.IsB4A Then
		'back key in Android
		If PrefDialog1.BackKeyPressed Then Return False
		If PrefDialog2.BackKeyPressed Then Return False
		If PrefDialog3.BackKeyPressed Then Return False
	End If
	If Viewing = "Product" Then
		GetCategories
		Return False
	End If
	DBClose
	Return True
End Sub

'Don't miss the code in the Main module + manifest editor.
Private Sub IME_HeightChanged (NewHeight As Int, OldHeight As Int)
	PrefDialog1.KeyboardHeightChanged(NewHeight)
	PrefDialog2.KeyboardHeightChanged(NewHeight)
	PrefDialog3.KeyboardHeightChanged(NewHeight)
End Sub

'#If B4J
'Private Sub SetScrollPaneBackgroundColor(View As CustomListView, Color As Int)
'	Dim SP As JavaObject = View.GetBase.GetView(0)
'	Dim V As B4XView = SP
'	V.Color = Color
'	Dim V As B4XView = SP.RunMethod("lookup", Array(".viewport"))
'	V.Color = Color
'End Sub
'#End If

Private Sub B4XPage_Appear
	'GetCategories
End Sub

Private Sub B4XPage_Resize(Width As Int, Height As Int)
	If PrefDialog1.IsInitialized And PrefDialog1.Dialog.Visible Then PrefDialog1.Dialog.Resize(Width, Height)
	If PrefDialog2.IsInitialized And PrefDialog2.Dialog.Visible Then PrefDialog2.Dialog.Resize(Width, Height)
	If PrefDialog3.IsInitialized And PrefDialog3.Dialog.Visible Then PrefDialog3.Dialog.Resize(Width, Height)
End Sub

#If B4J
Private Sub lblBack_MouseClicked (EventData As MouseEvent)
	GetCategories
End Sub
#Else
Private Sub lblBack_Click
	GetCategories
End Sub
#End If

Private Sub GetCategories
	Try
		Dim i As Int
		' ===  MiniORM start  ===
		DB.Table = "tbl_categories"
		DB.Query
		Dim Items As List = DB.Results
		' ===   MiniORM end   ===
		Dim Category(Items.Size) As Category
		For Each Item As Map In Items
			Category(i).Id = Item.Get("id")
			Category(i).Name = Item.Get("category_name")
			i = i + 1
		Next
		clvRecord.Clear
		For i = 0 To Category.Length - 1
			clvRecord.Add(CreateCategoryItems(Category(i).Name, clvRecord.AsView.Width), Category(i).Id)
		Next
		Viewing = "Category"
		lblTitle.Text = "Category"
		lblBack.Visible = False
		CreateDialog1
		CreateDialog2
		CreateDialog3
	Catch
		'Log(LastException)
		xui.MsgboxAsync(LastException.Message, "Error")
	End Try
End Sub

Private Sub GetProducts
	clvRecord.Clear
	' ===  MiniORM start  ===
	DB.Table = "tbl_products p"
	DB.Select = Array("p.*", "c.category_name")
	DB.Join = DB.CreateORMJoin("tbl_categories c", "p.category_id = c.id", "")
	DB.WhereValue(Array("c.id = ?"), Array(CategoryId))
	DB.Query
	Dim Items As List = DB.Results
	' ===   MiniORM end   ===
	For Each Item As Map In Items
		clvRecord.Add(CreateProductItems(Item.Get("product_code"), GetCategoryName(Item.Get("category_id")), Item.Get("product_name"), NumberFormat2(Item.Get("product_price"), 1, 2, 2, True), clvRecord.AsView.Width), Item.Get("id"))
	Next
	
	Viewing = "Product"
	lblTitle.Text = GetCategoryName(CategoryId)
	lblBack.Visible = True
End Sub

Private Sub GetCategoryName (Id As Int) As String
	Dim i As Int
	For i = 0 To Category.Length - 1
		If Category(i).Id = Id Then
			Return Category(i).Name
		End If
	Next
	Return ""
End Sub

Private Sub GetCategoryId (Name As String) As Int
	Dim i As Int
	For i = 0 To Category.Length - 1
		If Category(i).Name = Name Then
			Return Category(i).Id
		End If
	Next
	Return 0
End Sub

Private Sub clvRecord_ItemClick (Index As Int, Value As Object)
	If Viewing = "Category" Then
		CategoryId = Value
		GetProducts
	End If
End Sub

Private Sub btnNew_Click
	'If Category.Length = 0 Then Return
	If Viewing = "Product" Then
		Dim ProductMap As Map = CreateMap("Product Code": "", "Category": GetCategoryName(CategoryId), "Product Name": "", "Product Price": "", "id": 0)
		ShowDialog2("Add", ProductMap)
	Else
		Dim CategoryMap As Map = CreateMap("Category Name": "", "id": 0)
		ShowDialog1("Add", CategoryMap)
	End If
End Sub

Private Sub CreateCategoryItems (Name As String, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 90dip)
	p.LoadLayout("CategoryItem")
	lblName.Text = Name
	Return p
End Sub

Private Sub CreateProductItems (ProductCode As String, CategoryName As String, ProductName As String, ProductPrice As String, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 180dip)
	p.LoadLayout("ProductItem")
	lblCode.Text = ProductCode
	lblCategory.Text = CategoryName
	lblName.Text = ProductName
	lblPrice.Text = ProductPrice
	Return p
End Sub

Private Sub CreateDialog1
	PrefDialog1.Initialize(Root, "Category", 300dip, 70dip)
	PrefDialog1.Dialog.OverlayColor = xui.Color_ARGB(128, 0, 10, 40)
	PrefDialog1.Dialog.TitleBarHeight = 50dip
	PrefDialog1.LoadFromJson(File.ReadString(File.DirAssets, "template_category.json"))
End Sub

Private Sub CreateDialog2
	Dim categories As List
	categories.Initialize
	For i = 0 To Category.Length - 1
		categories.Add(Category(i).Name)
	Next
	PrefDialog2.Initialize(Root, "Product", 300dip, 250dip)
	PrefDialog2.Dialog.OverlayColor = xui.Color_ARGB(128, 0, 10, 40)
	PrefDialog2.Dialog.TitleBarHeight = 50dip
	PrefDialog2.LoadFromJson(File.ReadString(File.DirAssets, "template_product.json"))
	PrefDialog2.SetOptions("Category", categories)
	PrefDialog2.SetEventsListener(Me, "PrefDialog2") '<-- must add to handle events.
End Sub

Private Sub CreateDialog3
	PrefDialog3.Initialize(Root, "Delete", 300dip, 70dip)
	PrefDialog3.Theme = PrefDialog3.THEME_LIGHT
	PrefDialog3.Dialog.OverlayColor = xui.Color_ARGB(128, 0, 10, 40)
	PrefDialog3.Dialog.TitleBarHeight = 50dip
	PrefDialog3.Dialog.TitleBarColor = xui.Color_RGB(220, 20, 60)
	PrefDialog3.AddSeparator("default")
End Sub

Private Sub ShowDialog1 (Action As String, Item As Map)
	If Action = "Add" Then
		PrefDialog1.Dialog.TitleBarColor = xui.Color_RGB(50, 205, 50)
	Else
		PrefDialog1.Dialog.TitleBarColor = xui.Color_RGB(65, 105, 225)
	End If
	PrefDialog1.Title = Action & " Category"
	Dim sf As Object = PrefDialog1.ShowDialog(Item, "OK", "CANCEL")
	#if B4A or B4i
	PrefDialog1.Dialog.Base.Top = 100dip ' Make it lower
	#Else
	'Dim sp As ScrollPane = PrefDialog1.CustomListView1.sv
	'sp.SetVScrollVisibility("NEVER")
	Sleep(0)
	PrefDialog1.CustomListView1.sv.Height = PrefDialog1.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#End If
	' Fix Linux UI (Long Text Button)
	Dim btnCancel As B4XView = PrefDialog1.Dialog.GetButton(xui.DialogResponse_Cancel)
	btnCancel.Width = btnCancel.Width + 20dip
	btnCancel.Left = btnCancel.Left - 20dip
	btnCancel.TextColor = xui.Color_Red
	Dim btnOk As B4XView = PrefDialog1.Dialog.GetButton(xui.DialogResponse_Positive)
	btnOk.Left = btnOk.Left - 20dip
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If 0 = Item.Get("id") Then ' New row
			' ===  MiniORM start  ===
			DB.Table = "tbl_categories"
			DB.WhereValue(Array("category_name = ?"), Array(Item.Get("Category Name")))
			DB.Query
			'If DB.First.IsInitialized Then
			If DB.Found Then
				xui.MsgboxAsync("Category already exist", "Error")
				Return
			End If
			DB.Reset
			DB.Columns = Array("category_name")
			DB.Save2(Array(Item.Get("Category Name")))
			xui.MsgboxAsync("New category created!", $"ID: ${DB.First.Get("id")}"$)
			' ===   MiniORM end   ===
		Else
			' ===  MiniORM start  ===
			DB.Table = "tbl_categories"
			DB.Columns = Array("category_name")
			DB.Parameters = Array As String(Item.Get("Category Name"))
			DB.Id = Item.Get("id")
			DB.Save
			xui.MsgboxAsync("Category updated!", "Edit")
			' ===   MiniORM end   ===
		End If
		GetCategories
	Else
		Return
	End If
End Sub

Private Sub ShowDialog2 (Action As String, Item As Map)
	If Action = "Add" Then
		PrefDialog2.Dialog.TitleBarColor = xui.Color_RGB(50, 205, 50)
	Else
		PrefDialog2.Dialog.TitleBarColor = xui.Color_RGB(65, 105, 225)
	End If
	PrefDialog2.Title = Action & " Product"
	Dim sf As Object = PrefDialog2.ShowDialog(Item, "OK", "CANCEL")
	Sleep(0)
	PrefDialog2.CustomListView1.sv.Height = PrefDialog2.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If 0 = Item.Get("id") Then ' New row
			' ===  MiniORM start  ===
			DB.Table = "tbl_products"
			DB.setWhereValue(Array("product_code = ?"), Array As String(Item.Get("Product Code")))
			DB.Query
			If DB.Found Then
				xui.MsgboxAsync("Product Code already exist", "Error")
				Return
			End If
			If IsNumber(Item.Get("Product Price")) = False Then
				xui.MsgboxAsync("Product Price must be a number", "Error")
				Return
			End If
			DB.Reset
			DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
			Dim SelectedCategory As Int = GetCategoryId(Item.Get("Category"))
			DB.Save2(Array(SelectedCategory, Item.Get("Product Code"), Item.Get("Product Name"), Item.Get("Product Price")))
			CategoryId = SelectedCategory
			xui.MsgboxAsync("New product created!", $"ID: ${DB.First.Get("id")}"$)
			' ===   MiniORM end   ===
		Else
			' ===  MiniORM start  ===
			DB.Table = "tbl_products"
			DB.setWhereValue(Array("product_code = ?", "id <> ?"), Array As String(Item.Get("Product Code"), Item.Get("id")))
			DB.Query
			'Log(DB.ToString & " ")
			If DB.Found Then
				xui.MsgboxAsync("Product Code already exist", "Error")
				Return
			End If
			If IsNumber(Item.Get("Product Price")) = False Then
				xui.MsgboxAsync("Product Price must be a number", "Error")
				Return
			End If
			DB.Reset
			Dim NewCategoryId As Int = GetCategoryId(Item.Get("Category"))
			DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
			DB.Parameters = Array As String(NewCategoryId, Item.Get("Product Code"), Item.Get("Product Name"), Item.Get("Product Price"))
			DB.Id = Item.Get("id")
			DB.Save
			' ===   MiniORM end   ===
			xui.MsgboxAsync("Product updated!", "Edit")
			CategoryId = NewCategoryId
		End If
		GetProducts
	Else
		Return
	End If
End Sub

Private Sub ShowDialog3 (Item As Map, Id As Int)
	PrefDialog3.Title = "Delete " & Viewing
	Dim sf As Object = PrefDialog3.ShowDialog(Item, "OK", "CANCEL")
	#if B4A or B4i
	PrefDialog3.Dialog.Base.Top = 100dip ' Make it lower
	#Else
	' Fix Linux UI (Long Text Button)
	'Dim sp As ScrollPane = PrefDialog3.CustomListView1.sv
	'sp.SetVScrollVisibility("NEVER")
	Sleep(0)
	PrefDialog3.CustomListView1.sv.Height = PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#End If
	Dim btnCancel As B4XView = PrefDialog3.Dialog.GetButton(xui.DialogResponse_Cancel)
	btnCancel.Width = btnCancel.Width + 20dip
	btnCancel.Left = btnCancel.Left - 20dip
	btnCancel.TextColor = xui.Color_Red
	Dim btnOk As B4XView = PrefDialog3.Dialog.GetButton(xui.DialogResponse_Positive)
	btnOk.Left = btnOk.Left - 20dip
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Text = Item.Get("Item")
	#If B4i
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 16 ' Text too small in ios
	#Else
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 15 ' 14
	#End If
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Color = xui.Color_Transparent
	PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Color = xui.Color_Transparent
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		' ===  MiniORM start  ===
		If Viewing = "Product" Then
			DB.Table = "tbl_products"
		Else
			DB.Table = "tbl_categories"
		End If
		DB.Find(Id)
		If DB.Found Then
			DB.Reset
			DB.Id = Id
			DB.Delete
			xui.MsgboxAsync(Viewing &" deleted successfully", "Delete")
		Else
			xui.MsgboxAsync(Viewing & " not found", "Error")
		End If
		' ===   MiniORM end   ===
	Else
		Return
	End If
	If Viewing = "Product" Then
		GetProducts
	Else
		GetCategories
	End If
End Sub

Private Sub PrefDialog2_BeforeDialogDisplayed (Template As Object)
	Try
		' Fix Linux UI (Long Text Button)
		Dim btnCancel As B4XView = PrefDialog2.Dialog.GetButton(xui.DialogResponse_Cancel)
		btnCancel.Width = btnCancel.Width + 20dip
		btnCancel.Left = btnCancel.Left - 20dip
		btnCancel.TextColor = xui.Color_Red
		Dim btnOk As B4XView = PrefDialog2.Dialog.GetButton(xui.DialogResponse_Positive)
		If btnOk.IsInitialized Then
			btnOk.Width = btnOk.Width + 20dip
			btnOk.Left = btnCancel.Left - btnOk.Width
		End If
	Catch
		Log(LastException)
	End Try
End Sub

Private Sub btnEdit_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim lst As B4XView = clvRecord.GetPanel(Index)
	If Viewing = "Product" Then
		If CategoryId = 0 Then Return
		Dim ProductId As Int = clvRecord.GetValue(Index)
		Dim pnl As B4XView = lst.GetView(0)
		Dim v1 As B4XView = pnl.GetView(0)
		#If B4i
		Dim v2 As B4XView = pnl.GetView(1).GetView(0) ' using panel
		#Else
		Dim v2 As B4XView = pnl.GetView(1)
		#End If
		Dim v3 As B4XView = pnl.GetView(2)
		Dim v4 As B4XView = pnl.GetView(3)
		Dim ProductMap As Map = CreateMap("Product Code": v1.Text, "Category": v2.Text, "Product Name": v3.Text, "Product Price": v4.Text.Replace(",", ""), "id": ProductId)
		ShowDialog2("Edit", ProductMap)
	Else
		CategoryId = clvRecord.GetValue(Index)
		Dim pnl As B4XView = lst.GetView(0)
		Dim v1 As B4XView = pnl.GetView(0)
		Dim CategoryMap As Map = CreateMap("Category Name": v1.Text, "id": CategoryId)
		ShowDialog1("Edit", CategoryMap)
	End If
End Sub

Private Sub btnDelete_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim Id As Int = clvRecord.GetValue(Index)
	Dim lst As B4XView = clvRecord.GetPanel(Index)
	Dim pnl As B4XView = lst.GetView(0)
	If Viewing = "Product" Then
		If CategoryId = 0 Then Return
		Dim v1 As B4XView = pnl.GetView(2)
	Else
		CategoryId = clvRecord.GetValue(Index)
		Dim v1 As B4XView = pnl.GetView(0)
	End If
	Dim M1 As Map
	M1.Initialize
	M1.Put("Item", v1.Text)
	ShowDialog3(M1, Id)
End Sub