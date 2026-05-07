/*****************************************************************************************
Class Name    	: PC_AwsTextractParser
Description     : AWS Textract Response Parser Class.
Created By      : Deloitte
Created Date    : May 03, 2021
Modification Log:
--------------------------------------------------------------------------------------------
Developer                   Date                   Description
---------------------------------------------------------------------------------------------
Satheesh Kumar             May 03, 2021           Initial Version
*********************************************************************************************/
// Credits to AWS for response parser samples (https://github.com/aws-samples/amazon-textract-response-parser/blob/master/src-csharp/TextractExtensions.cs)

public with sharing class PC_AwsTextractParser implements PC_OCR.ResponseParser {

    public Map<String, String> getFormData(String jsonResponse) {
        Map<String, String> formResponseMap = new Map<String, String>();
        Map<String, Integer> fieldCountMap = new Map<String, Integer>();
        List<PC_AwsTextractResponse> gdaResponse = PC_AwsTextractResponse.parse(jsonResponse);
        TextractDocument document = new TextractDocument(gdaResponse);

        String key, value;
        Integer formFieldCount = 0;
        for (PageX page : document.Pages) {
            for (Field f : page.Form.Fields) {
                key = (f.Key)?.toString();
                value = (f.Value)?.toString();
                if(String.isNotBlank(key)) {
                    if (formResponseMap.containsKey(key)) {
                        formFieldCount = (fieldCountMap.get(key))+1;
                        fieldCountMap.put(key, formFieldCount);
                        formResponseMap.put(key + '_' + fieldCountMap.get(key), value);
                    } else {
                        fieldCountMap.put(key, 0);
                        //system.debug(String.valueOf(f.Value));
                        formResponseMap.put(key, value);
                    }
                }
            }
        }
        system.debug('formResponseMap---'+JSON.serialize(formResponseMap));
        return formResponseMap;
    }

    public virtual class Geometry {
        public BoundingBox BoundingBox;
        public List<Polygon> Polygon;
    }

    public virtual class Relationships {
        public List<String> Ids;
        public String Type;
    }

    public inherited sharing class Block {
        public String BlockType;
        public Integer ColumnIndex;
        public Integer ColumnSpan;
        public Double Confidence;
        public List<String> EntityTypes;
        public Geometry Geometry;
        public String Id;
        public Integer Page;
        public List<Relationships> Relationships;
        public Integer RowIndex;
        public Integer RowSpan;
        public String SelectionStatus;
        public String Text;
        public String TextType;
    }

    public virtual class BoundingBox {
        public Double Height;
        public Double Left;
        public Double Top;
        public Double Width;
    }

    public inherited sharing class Polygon {
        public Double X;
        public Double Y;
    }


    /**   ------------------*/

    public inherited sharing class Word {
        public Block Block { get; set; }
        public Double Confidence { get; set; }
        public Geometry Geometry { get; set; }
        public string Id { get; set; }
        public string Text { get; set; }

        public Word(Block block, List<Block> blocks) {
            this.Block = block;
            this.Confidence = block.Confidence;
            this.Geometry = block.Geometry;
            this.Id = block.Id;
            this.Text = block == null ? PC_Constants.EMPTY_STRING : block.Text;
        }

        public override string ToString() {
            return Text;
        }
    }

    public inherited sharing class TextractDocument {
        private List<Block> blockMap = new List<Block>();
        List<List<Block>> documentPages = new List<List<Block>>();
        public List<PC_AwsTextractResponse> ResponsePages { get; set; }
        public List<PageX> Pages { get; set; }
        public List<List<Block>> PageBlocks {
            get {return this.documentPages;}
        }

        public TextractDocument(List<PC_AwsTextractResponse> response) {
            this.Pages = new List<PageX>();
            this.ResponsePages = new List<PC_AWSTextractResponse>();
            this.ResponsePages.addAll(response);

            this.ParseDocumentPagesAndBlockMap();
            this.Parse();
        }

        private void ParseDocumentPagesAndBlockMap() {
            List<Block> documentPage = null;
            for (PC_AwsTextractResponse page : this.ResponsePages) {
                String blocksJsonString = JSON.serialize(page.Blocks);
                List<Block> blocks = page.Blocks; //(List<Block>) JSON.deserialize(blocksJsonString, List<Block>.class);
                for (Block block : blocks) {
                    this.blockMap.add(block);
                    if (block.BlockType == 'PAGE') {
                        if (documentPage != null) {
                            this.documentPages.add(documentPage);
                        }
                        documentPage = new List<Block>();
                        documentPage.add(block);
                    } else {
                        documentPage.add(block);
                    }
                }
            }

            if (documentPage != null) {
                this.documentPages.add(documentPage);
            }

        }

        private void Parse() {
            for (List<Block> documentPage : this.documentPages) {
                PageX page = new PageX(documentPage, this.blockMap);
                this.Pages.add(page);
            }
        }

        public Block GetBlockById(string blockId) {
            for (Block b : blockMap) {
                if (b.Id == blockId) {
                    return b;
                }
            }
            return null;
        }
    }

    public inherited sharing class Table {
        public List<Row> Rows { get; set; }
        public Block Block { get; set; }
        public Double Confidence { get; set; }
        public Geometry Geometry { get; set; }
        public string Id { get; set; }

        public Table(Block block, List<Block> blocks) {
            this.Block = block;
            this.Confidence = block.Confidence;
            this.Geometry = block.Geometry;
            this.Id = block.Id;
            this.Rows = new List<Row>();
            Integer ri = 1;
            Row row = new Row();

            List<Relationships> relationships = block.Relationships;
            if (relationships != null && relationships.size() > 0) {
                for (Relationships r : relationships) {
                    if (r.Type == 'CHILD') {
                        for (String id : r.Ids) {
                            Block cBlock = new Block();
                            for (Block b : blocks) {
                                if (b.Id == id) {
                                    cBlock = b;
                                    break;
                                }
                            }
                            Cell cell = new Cell(cBlock, blocks);
                            if (cell.RowIndex > ri) {
                                this.Rows.add(row);
                                row = new Row();
                                ri = cell.RowIndex;
                            }
                            row.Cells.add(cell);
                        }
                        if (row != null && row.Cells.size() > 0) {
                            this.Rows.add(row);
                        }
                    }
                }
            }
        }

        public override String ToString() {
            List<String> result = new List<String>();
            result.add(String.format('Table{0}===={0}', new List<Object> {'\n'}));
            for (Row r : this.Rows) {
                result.add(String.format('Row{0}===={0}{1}{0}', new List<Object> {'\n', r}));
            }
            return String.join(result, '');
        }
    }

    public inherited sharing class SelectionElement {
        public Double Confidence { get; set; }
        public Geometry Geometry { get; set; }
        public string Id { get; set; }
        public string SelectionStatus { get; set; }

        public SelectionElement(Block block, List<Block> blocks) {
            this.Confidence = block.Confidence;
            this.Geometry = block.Geometry;
            this.Id = block.Id;
            this.SelectionStatus = block.SelectionStatus;
        }
    }

    public inherited sharing class Row {
        public List<Cell> Cells { get; set; }
        public Row() {
            this.Cells = new List<Cell>();
        }

        public override String ToString() {
            List<String> result = new List<String>();
            for (Cell c : this.Cells) {
                result.add(String.format('[{0}]', new List<Object>{c}));
            }
            return String.join(result, '');
        }
    }

    public inherited sharing class PageX {
        public PageX(List<Block> blocks, List<Block> blockMap) {
            this.Blocks = blocks;
            this.Text = PC_Constants.EMPTY_STRING;
            this.Lines = new List<Line>();
            this.Form = new Form();
            this.Tables = new List<Table>();
            this.Content = new List<Object>();

            for (Block b : blocks) {
                if (b.BlockType == 'PAGE') {
                    this.Geometry = new NewGeometry(b.Geometry);
                    this.Id = b.Id;
                /*} else if (b.BlockType == 'LINE') {
                    Line l = new Line(b, blockMap);
                    this.Lines.add(l);
                    this.Content.add(l);
                    this.Text = this.Text + l.Text + '\n';
                } else if (b.BlockType == 'TABLE') {
                    Table t = new Table(b, blockMap);
                    this.Tables.add(t);
                    this.Content.add(t);*/
                } else if (b.BlockType == 'KEY_VALUE_SET') {
                    if (b.EntityTypes.contains('KEY')) {
                        Field f = new Field(b, blockMap);
                        if (f.Key != null) {
                            this.Form.addField(f);
                            this.Content.add(f);
                        }
                    }
                }
            }
        }
        public List<Block> Blocks { get; set; }
        public String Text { get; set; }
        public List<Line> Lines { get; set; }
        public Form Form { get; set; }
        public List<Table> Tables { get; set; }
        public List<Object> Content { get; set; }
        public Geometry Geometry { get; set; }
        public String Id { get; set; }

        public override string ToString() {
            List<String> result = new List<String>();
            result.add(String.format('Page{0}===={0}', new List<Object>{'\n'}));
            for (Object c : this.Content) {
                result.add(String.format('{1}{0}', new List<Object>{'\n', c}));
            }
            return String.join(result, '');
        }
    }

    public inherited sharing class Column {
        public Double Left { get; set; }
        public Double Right { get; set; }
        public override string ToString() {
            return String.format('Left: {0}, Right :{1}', new List<Object>{this.Left, this.Right});
        }
    }

    public inherited sharing class IndexedText {
        public Integer ColumnIndex { get; set; }
        public string Text { get; set; }

        public override String ToString() {
            return String.format('[{0}] {1}', new List<Object>{this.ColumnIndex, this.Text});
        }
    }

    public inherited sharing class NewGeometry extends Geometry {
        public NewGeometry(Geometry geometry) {
            super();
            this.BoundingBox = geometry.BoundingBox;
            this.Polygon = geometry.Polygon;
            BoundingBox = new NewBoundingBox(this.BoundingBox.Width, this.BoundingBox.Height, this.BoundingBox.Left, this.BoundingBox.Top);
            Polygon = this.Polygon;
        }
        public override String ToString() {
            return String.format('BoundingBox: {0}{1}', new List<Object>{BoundingBox, '\n'});
        }
    }

    public inherited sharing class NewBoundingBox extends BoundingBox {
        public NewBoundingBox(Double width, Double height, Double left, Double top) {
            super();
            this.Width = width;
            this.Height = height;
            this.Left = left;
            this.Top = top;
        }

        public override String ToString() {
            return String.format('width: {0}, height: {1}, left: {2}, top: {3}', new List<Object>{Width, Height, Left, Top});
        }
    }

    public inherited sharing class Line {
        public Double Confidence { get; set; }
        public Geometry Geometry { get; set; }
        public string Id { get; set; }
        public List<Word> Words { get; set; }
        public string Text { get; set; }
        public Block Block { get; set; }

        public Line(Block block, List<Block> blocks) {
            this.Block = block;
            this.Confidence = block.Confidence;
            this.Geometry = block.Geometry;
            this.Id = block.Id;
            this.Text = block == null ? PC_Constants.EMPTY_STRING : block.Text;
            this.Words = new List<Word>();

            List<Relationships> relationships = block.Relationships;
            if (relationships != null && relationships.size() > 0) {
                for (Relationships r : relationships) {
                    if (r.Type == 'CHILD') {
                        for (String id : r.Ids) {
                            Block tBlock;
                            for (Block b : blocks) {
                                if (b.BlockType == 'WORD' && b.Id == id) {
                                    tBlock = b;
                                    break;
                                }
                            }
                            this.Words.add(new Word(tBlock, blocks));
                        }
                    }
                }
            }
        }

        public override String ToString() {
            return String.format('Line{0}===={0}{1} {0}Words{0}----{0}{2}{0}----', new List<Object> {'\n', this.Text, String.join(this.Words, ', ')});
        }

    }

    public inherited sharing class Form {
        public List<Field> Fields { get; set; }
        private Map<String, Field> fieldMap;

        public Form() {
            this.Fields = new List<Field>();
            this.fieldMap = new Map<String, Field>();
        }

        public void AddField(Field field) {
            this.Fields.add(field);
            this.fieldMap.put(String.valueOf(field.Key), field);
        }
        public Field GetFieldByKey(String key) {
            return this.fieldMap.get(key);
        }

        public List<Field> SearchFieldsByKey(String key) {
            List<Field> searchFields = new List<Field>();
            for (Field f : this.Fields) {
                if (String.valueOf(f.Key).toLowerCase().contains(key.toLowerCase())) {
                    searchFields.add(f);
                }
            }
            return searchFields;
        }

        public override String ToString() {
            return String.join(this.Fields, '\n');
        }
    }

    public inherited sharing class FieldValue {
        public List<Object> Content { get; set; }
        public Block Block { get; set; }
        public Double Confidence { get; set; }
        public Geometry Geometry { get; set; }
        public string Id { get; set; }
        public string Text { get; set; }

        public FieldValue(Block block, List<string> children, List<Block> blocks) {
            this.Block = block;
            this.Confidence = block.Confidence;
            this.Geometry = block.Geometry;
            this.Id = block.Id;
            this.Text = PC_Constants.EMPTY_STRING;
            this.Content = new List<Object>();

            List<String> words = new List<String>();
            if (children != null && children.size() > 0) {
                for (String c : children) {
                    Block wordBlock = new Block();
                    for (Block b : blocks) {
                        if (b.Id == c) {
                            wordBlock = b;
                            break;
                        }
                    }
                    if (wordBlock.BlockType == 'WORD') {
                        Word w = new Word(wordBlock, blocks);
                        this.Content.add(w);
                        words.add(w.Text);
                    } else if (wordBlock.BlockType == 'SELECTION_ELEMENT') {
                        SelectionElement selection = new SelectionElement(wordBlock, blocks);
                        this.Content.add(selection);
                        words.add(selection.SelectionStatus);
                    }
                }
            }

            if (words.size() > 0) {
                this.Text = string.join(words, ' ');
            }
        }

        public override String ToString() {
            return Text;
        }
    }

    public inherited sharing class FieldKey {
        public List<Object> Content { get; set; }
        public Block Block { get; set; }
        public Double Confidence { get; set; }
        public Geometry Geometry { get; set; }
        public string Id { get; set; }
        public string Text { get; set; }

        public FieldKey(Block block, List<String> children, List<Block> blocks) {
            this.Block = block;
            this.Confidence = block.Confidence;
            this.Geometry = block.Geometry;
            this.Id = block.Id;
            this.Text = PC_Constants.EMPTY_STRING;
            this.Content = new List<Object>();

            List<String> words = new List<String>();
            if(children != null && children.size() > 0) {
                for (String c : children) {
                    Block wordBlock = new Block();
                    for (Block b : blocks) {
                        if (b.Id == c) {
                            wordBlock = b;
                            break;
                        }
                    }
                    if (wordBlock.BlockType == 'WORD') {
                        Word w = new Word(wordBlock, blocks);
                        this.Content.add(w);
                        words.add(w.Text);
                    }
                }
            }
            if(words.size() > 0) {
                this.Text = string.join(words, ' ');
            }
        }

        public override string ToString() {
            return Text;
        }
    }

    public inherited sharing class Field {
        public FieldKey Key { get; set; }
        public FieldValue Value { get; set; }

        public Field(Block block, List<Block> blocks) {
            List<Relationships> relationships = block.Relationships;
            if(relationships != null && relationships.size() > 0) {
                for (Relationships r : relationships) {
                    if (r.Type == 'CHILD') {
                        this.Key = new FieldKey(block, r.Ids, blocks);
                    } else if (r.Type == 'VALUE') {
                        for (String id : r.Ids) {
                            Block v = new Block();
                            for (Block b : blocks) {
                                if (b.Id == id) {
                                    v = b;
                                    break;
                                }
                            }
                            if (v.EntityTypes.Contains('VALUE')) {
                                List<Relationships> vr = v.Relationships;
                                if (vr != null && vr.size() > 0) {
                                    for (Relationships vc : vr) {
                                        if (vc.Type == 'CHILD') {
                                            this.Value = new FieldValue(v, vc.Ids, blocks);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        public override string ToString() {
            String k = this.Key == null ? PC_Constants.EMPTY_STRING : this.Key.ToString();
            String v = this.Value == null ? PC_Constants.EMPTY_STRING : this.Value.ToString();
            return String.format('{0}Field{0}===={0}Key: {1}, Value: {2}', new List<Object> {'\n', k, v});
        }
    }

    public inherited sharing class Cell {
        public Integer RowIndex { get; set; }
        public Integer RowSpan { get; set; }
        public Integer ColumnIndex { get; set; }
        public Integer ColumnSpan { get; set; }
        public List<Object> Content { get; set; }
        public Block Block { get; set; }
        public Double Confidence { get; set; }
        public Geometry Geometry { get; set; }
        public String Id { get; set; }
        public String Text { get; set; }

        public Cell(Block block, List<Block> blocks) {
            this.Block = block;
            this.ColumnIndex = block.ColumnIndex;
            this.ColumnSpan = block.ColumnSpan;
            this.Confidence = block.Confidence;
            this.Content = new List<Object>();
            this.Geometry = block.Geometry;
            this.Id = block.Id;
            this.RowIndex = block.RowIndex;
            this.RowSpan = block.RowSpan;
            this.Text = PC_Constants.EMPTY_STRING;

            List<Relationships> relationships = block.Relationships;
            if (relationships != null && relationships.size() > 0) {
                for (Relationships r : relationships) {
                    if (r.Type == 'CHILD') {
                        for (String id : r.Ids) {
                            Block rb = new Block();
                            for (Block b : blocks) {
                                if (b.Id == id) {
                                    rb = b;
                                    break;
                                }
                            }
                            if (rb.BlockType == 'WORD') {
                                Word w = new Word(rb, blocks);
                                this.Content.add(w);
                                this.Text = this.Text + w.Text + ' ';
                            } else if (rb.BlockType == 'SELECTION_ELEMENT') {
                                SelectionElement se = new SelectionElement(rb, blocks);
                                this.Content.add(se);
                                this.Text = this.Text + se.SelectionStatus + ', ';
                            }
                        }
                    }
                }
            }
        }

        public override string ToString() {
            return this.Text;
        }
    }
}