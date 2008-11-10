require 'rubygems'
require 'roo'
require 'test/unit'
require 'flexmock/test_unit'
require 'logger'

  class NilSpreadsheetKey < RuntimeError; end
  class NilCoordinates < RuntimeError; end
  class SpreadsheetNotLoaded < RuntimeError; end
  class AliasNotFound < RuntimeError; end
  class XNotFound < RuntimeError; end
  class YNotFound < RuntimeError; end
    

  class GoldenRetriever
    
    SPREADSHEET_ALIAS = {'test1' => 'p38-cEwIpu6U2N1uY1lh5TA'}
    
    def initialize(spreadsheet_key = nil)
      raise NilSpreadsheetKey if spreadsheet_key.nil?
      
      @spreadsheet_key = resolve_alias(spreadsheet_key)
      
      @log = Logger.new('./retriever.log') 
      
    end

   
    def retrieve(x = nil, y = nil)
      
      @log.info("Buscando x: #{x}, y: #{y}")
      
            
      raise NilCoordinates if (x.nil? or y.nil?)
      
      @spreadsheet ||= get_spreadsheet
      
      raise SpreadsheetNotLoaded if @spreadsheet.nil?
      
      x_header = @spreadsheet.row(1)
      y_header = @spreadsheet.column(1)
      
      @log.info("xheader: #{x_header.inspect} / yheader: #{y_header.inspect}")
       
      raise XNotFound unless x_header.include?(x)
      raise YNotFound unless y_header.include?(y)
      
      x_pos = x_header.index(x) + 1
      y_pos = y_header.index(y) + 1
      
      
      value = @spreadsheet.cell(y_pos, x_pos)
      @log.info("x_pos: #{x_pos} (#{x}), y_pos: #{y_pos} (#{y}) => #{value}")
      
      value    
      
    end
  
  
    private
    
    def resolve_alias(spreadsheet_alias)
      raise AliasNotFound unless SPREADSHEET_ALIAS.has_key?(spreadsheet_alias)
      SPREADSHEET_ALIAS[spreadsheet_alias]
    end
  
    def get_spreadsheet
      x1 = Google.new(@spreadsheet_key)
      x1.default_sheet = x1.sheets.first
      x1
    end
  
  end


  class GoldenRetrieverTest < Test::Unit::TestCase
    
    SPREADSHEET_KEY = 'test1'

    def test_should_require_spreadsheet_key
      assert_raise NilSpreadsheetKey do
        g = GoldenRetriever.new(nil) 
      end
    end
    
    def test_should_require_x_coordinate
      
      do_mock
      
      assert_raise NilCoordinates do
        g = GoldenRetriever.new(SPREADSHEET_KEY) 
        g.retrieve(nil,'bar')
      end
    end
  
    def test_should_require_y_coordinate
      
      do_mock
      
      assert_raise NilCoordinates do
        g = GoldenRetriever.new(SPREADSHEET_KEY) 
        g.retrieve('foo',nil)
      end
    end
    
    def test_should_retrieve_right_values
      do_mock
      g = GoldenRetriever.new(SPREADSHEET_KEY) 
      
      {'xfoo,yfoo' => 1.0, 'xfoo,ybar' => 3.0, 'xbar,yfoo' => 2.0, 'xbar,ybar' => 4.0, 'xbaz,ybar' => 6.0 , 'xfoo,ybaz' => 7.0, 'xbar,ybaz' => 8.0, 'xbaz,ybaz' => 9.0}.each_pair do |coord,v| 
        c = coord.split(',')
        r = g.retrieve(c[0],c[1])
        assert_equal v, r, "Coords: #{coord}"
      end
      
    end
    
    def test_should_require_valid_alias_for_spreadsheet
      assert_raise AliasNotFound do
        g = GoldenRetriever.new('foo') 
      end
    end
    
    def test_should_resolve_valid_alias
      assert_nothing_raised  do
        g = GoldenRetriever.new('test1')
      end
    end
    
    def do_mock
      
      rows = [[],[nil,"xfoo","xbar",'xbaz'],['yfoo',1.0,2.0,5.0],['ybar',3.0,4.0,6.0],['ybaz',7.0,8.0,9.0]]
      cols = [[],[nil,"yfoo","ybar","ybaz"],['xfoo',1.0,3.0,7.0],['xbar',2.0,4.0,8.0],['xbaz',5.0,6.0,9.0]] 
      
      
      f = flexmock(Google).new_instances do |instance|
        
        instance.should_receive(:sheets).and_return(['Sheet1'])
        instance.should_receive(:default_sheet=).and_return('Sheet1')    
          
        (1..(rows.size-1)).each do |i|
          instance.should_receive(:row).with(i).and_return(rows[i])
        end  
        
        (1..(cols.size-1)).each do |i|
          instance.should_receive(:column).with(i).and_return(cols[i])
        end
        
        instance.should_receive(:cell).with(Integer,Integer).and_return { |y_pos,x_pos|
          rows[y_pos][x_pos-1]
        }
                
      end
      
    end
  
  end