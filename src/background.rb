class Processor
  def initialize(parser: Parser, loader: Loader)
    @parser = parser
    @loader = loader
  end

  def process(csv_file)
    begin
      parsed = parser.parse(csv_file)
      loader.load!(parsed)

      Result.new(:success)
    rescue ActiveRecord::RecordInvalid => invalid
      Result.new(:failed, invalid.record.errors)
    end
  end
end
