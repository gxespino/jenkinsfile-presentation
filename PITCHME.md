### Stubs, Mocks, Spies and Fakes
(Nothing is real anymore)

---

### TIL:

- Stubs
- Mocks
- Spies
- Fakes
- When, how and why to use either

---

### Background

+++?code=src/background.rb&lang=ruby

+++

```ruby
class Parser
  def self.parse(csv_file)
    ...
  end
end

class Loader
  def self.load!(parsed_data)
    ...
  end
end
```

---

### Stubs

```ruby
describe '#process' do
  it 'returns a successful Result object' do
    processor = Processor.new

    result = processor.process('test_file.csv')

    expect(result.successful?).to eq(true)
  end
end
```

No stubs in place. Object and it's tests are tightly _coupled_ to it's dependencies

+++

```ruby
describe '#process' do
  it 'returns a successful Result object' do
    parser    = double('parser')
    loader    = double('loader')
    processor = Processor.new(parser: parser, loader: loader)
    allow(parser).to receive(:parse).and_return('PARSED')
    allow(loader).to receive(:load!).and_return(Result.new(:success))

    result = processor.process('test_file.csv')

    expect(result.successful?).to eq(true)
  end
end
```

@[3-4](Using RSpec's `double` method as a stand in Object)
@[6-7](_Stubbing_ our collaborators internal implementation with our test doubles)

---

Stubs are great for QUERY methods
But they don't suffice for COMMAND methods

+++

```ruby
def process(csv_file)
  begin
    parsed = parser.parse(csv_file)
    loader.load!(parsed)

    Result.new(:success)
  rescue ActiveRecord::RecordInvalid => invalid
    Result.new(:failed, invalid.record.errors)
  end
end
```

@[1-2, 5-10](Using stubs our test would still pass if we removed these two lines!)

+++

What should we do instead?

---

### Mocks

```ruby
describe '#process' do
  it 'returns a successful Result object' do
    parser    = double('parser')
    loader    = double('loader')
    processor = Processor.new(parser: parser, loader: loader)
    expect(parser).to receive(:parse).and_return('PARSED')
    expect(loader).to receive(:load!).and_return(Result.new(:success))

    result = processor.process('test_file.csv')

    expect(result.successful?).to eq(true)
  end
end
```

@[3-4](Still using the same Doubles)
@[6-7](A mock is just like a stub, except that it doesn't just allow methods to be invoked; it expects it.)

+++

stubs = allow

mocks = expect

+++

Is Loading into a Database a Command or a Query? How does this affect whether or not we should use a stub vs mock?

+++

Downside: Mocks muddle up our tests by setting expectations out of order

+++

```ruby
describe '#process' do
  it 'returns a successful Result object' do
    parser    = double('parser')
    loader    = double('loader')
    processor = Processor.new(parser: parser, loader: loader)
    expect(parser).to receive(:parse).and_return('PARSED')
    expect(loader).to receive(:load!).and_return(Result.new(:success))

    result = processor.process('test_file.csv')

    expect(result.successful?).to eq(true)
  end
end
```

@[3-5](Arrange)
@[9](Act)
@[11](Assert)
@[6-7](Arrange/Assert/Both?/WTH!?)

---

### Spies

```ruby
describe '#process' do
  it 'returns a successful Result object' do
    parser    = double('parser')
    loader    = double('loader')
    processor = Processor.new(parser: parser, loader: loader)
    allow(parser).to receive(:parse).and_return('PARSED')
    allow(loader).to receive(:load!).and_return(Result.new(:success))

    result = processor.process('test_file.csv')

    expect(parser).to have_received(:parse).with('test_file.csv')
    expect(loader).to have_received(:load!)
    expect(result.successful?).to eq(true)
  end
end
```

@[3-7](Arrange)
@[9](Act)
@[11-13](Assert)
@[6-7, 11-12](Spy)

+++

Spies are ALSO stubs. They just also have an explicit expectation.

+++

Benefits of Spies:

- Tests are organized clearly in Arrange, Act, Assert <!-- .element: class="fragment" -->
- Easier to understand <!-- .element: class="fragment" -->
- Easier to extract repeated Arrange steps <!-- .element: class="fragment" -->

Downsides of Spies: <!-- .element: class="fragment" -->

- Some duplication (overcome this by extraction) <!-- .element: class="fragment" -->

+++

```ruby
describe '#process' do
  it 'returns a successful Result object' do
    parser    = stubbed_parser
    loader    = stubbed_loader
    processor = Processor.new(parser: parser, loader: loader)

    result = processor.process('test_file.csv')

    expect(parser).to have_received(:parse).with('test_file.csv')
    expect(loader).to have_received(:load!)
    expect(result.successful?).to eq(true)
  end
end

def stubbed_parser
  parser = double('parser')
  allow(parser).to receive(:parse).and_return('PARSED')
  parser
end

def stubbed_loader
  loader = double('losser')
  allow(loader).to receive(:load!).and_return(Result.new(:success))
  loader
end
```

---

### Fakes

Fake objects that totally replace an external system. e.g. FakeStripe, FakePCS, FakeNewRelic

+++

```ruby
describe DecisionProcess do
  describe '.decide' do
    it 'fetches an account from PCS' do
      account_id = '123'
      allow(PCSClient)
        .to receive(:fetch)
        .with(account_id: account_id)
        .and_return(FakePCSClient.fetch('123'))

      result = DecisionProcess.decide(account_id: account_id)

      expect(result).to eq(:success)
    end
  end
end
```

@[5](Real client)
@[8](Fake client)

+++

You don't need Fakes, you can just stub, spy, or mock everything. 

But, they can be really useful for replacing a large dependency.

+++

Benefits of Fakes:

- Clean solution for a dependency requiring a lot of the same mocks <!-- .element: class="fragment" -->

Downsides of Fakes: <!-- .element: class="fragment" -->

- A lot of code and maintenance required for when the real object changes <!-- .element: class="fragment" -->

---

### But wait! There's more!

+++

```ruby
describe '#process' do
  it 'returns a successful Result object' do
    parser = spy('parser')
    loader = spy('loader')
    processor  = Processor.new(parser: parser, loader: loader)

    result = processor.process('test_file.csv')

    expect(parser).to have_received(:parse).with('test_file.csv')
    expect(loader).to have_received(:load!)
    expect(result.successful?).to eq(true)
  end
end
```

@[3-4](#spy method added in RSpec 3.1. Spy automatically stubs all messages for that object)

+++

TLDR:

- Query - return a result and do not alter application state (no side effects) <!-- .element: class="fragment" -->
- Command - alters application state (send emails, alter DB, etc.) <!-- .element: class="fragment" -->

+++

TLDR CONT:

- STUB: if your object under test is calling another object’s query method. You do not actually care if that query method is called as long as the object under test ultimately does what it should. <!-- .element: class="fragment" -->
- SPY: if you want to ensure that a message was a received by an object. This is necessary when you are calling a command method. <!-- .element: class="fragment" -->
- MOCKS: Eh, lean towards Spies as they don't break Arrange - Act - Assert. Spies used to add some code duplication but this is alleviated with code extraction or the new #spy method. <!-- .element: class="fragment" -->

---
