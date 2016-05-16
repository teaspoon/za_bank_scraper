module ZaBankScraper
  class Absa

    attr_accessor :base_url, :account_number, :pin, :password, :user_number, :date_from, :date_to

    def initialize(options={})
      @base_url = "https://ib.absa.co.za/ib/AuthenticateW.do"

      @agent = Mechanize.new
      @account_number = options[:account_number]
      @pin = options[:pin]
      @user_number = options[:user_number]
      @password = options[:password]
      @date_from = options[:date_from]
      @date_to = options[:date_to]
    end

    def pretty_print
      array = []
      array << [ "Date", "T.Num", "Acc Num", "Description", "Dep Id", "Amount", "Balance"]
      scrape.each do |t|
        array << [t[:remittance_date], t[:transaction_number_for_day], t[:account_number],t[:description], t[:dep_id], t[:amount], t[:account_balance_after_transaction] ]
      end

      puts array.to_table
    end

    def scrape
      agent = Mechanize.new
      agent.get(base_url) # mobi
      agent.keep_alive = false

      # Page 1 of login form
      agent.page.forms[0]['AccessAccount'] = account_number
      agent.page.forms[0]['PIN'] = pin
      agent.page.forms[0]['user'] = user_number
      agent.submit(agent.page.forms[0], agent.page.forms[0].button_with(:name => 'button_processPIN'))

      # Page 2 of login form
      (1..password.length).each do |digit|
        if agent.page.forms[0]["DIGITOUT#{digit-1}"].nil?
          agent.page.forms[0]["DIGIT#{digit-1}"] = password[digit-1]
        end
      end

      agent.submit(agent.page.forms[0], agent.page.forms[0].button_with(:name => 'button_processPassword'))

      # Go to My Account

      agent.page.links[0].click

      # Go to Statement

      agent.page.links[1].click

      # Go to a specific account for last 2 days

      select_list = agent.page.forms[0].field_with(:name => "SelectAccount")

      html_transactions = []
      select_list.options.select.each do |select|

        account_number = select.text[0,10]
        # p "--------------BEGIN--------------"
        html_transactions.push get_transactions_for_account(agent, account_number, date_from, date_to)
        # p "---------------END---------------"
        agent.submit(agent.page.forms[0], agent.page.forms[0].button_with(:name => 'button_promptSelectionCriteria'))

      end

      html_transactions.flatten
    end

    def get_transactions_for_account(agent, account_number, date_from, date_to)
      search_page = agent.page.form_with(:action => 'https://ib.absa.co.za/ib/TranHistoryW.do') do |f|
        f.field_with(:name => "SelectAccount").value = f.field_with(:name => "SelectAccount").options.select {|o| o.text.start_with? account_number}[0]
        f.field_with(:name => "dateRange").value = f.field_with(:name => "dateRange").options.select {|o| o.text.start_with? 'Custom'}[0]
        f.fromDate       = date_from
        f.toDate         = date_to
      end.submit agent.page.forms[0].button_with(:name => 'button_View')

      # fetch transactions
      results = []
      array = []
      button = true

      temp_date = Date.strptime(date_from, "%Y%m%d").to_s
      count = 1

      while button

        html_transactions = agent.page.parser.xpath("//p[contains(@class, 'alt')]")

        html_transactions.map do |transaction|
          array = transaction.children.select {|child| child.name == "text"}.map {|child| child.content.gsub(/\t/, '').gsub(/\r\n/, '').strip}

          if array.length == 5
            dep_id = ''
            if array.select {|elem| elem.empty?}.empty?
              dep_id = array[-3]
              amount = array[-2].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
            else
              amount = array[-3].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
            end
            account_balance_after_transaction = array[-1].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
          elsif array.length == 7
            dep_id = array[2] + array[3]
            amount = array[-3].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
            account_balance_after_transaction = array[-1].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
          elsif array.length == 4
            # ["2015-07-28", "CASH DEP BRANCH     RICHARDS B(    123,00 )", "R 8 000.00", "69 155.95"]
            dep_id = ""
            amount = array[-2].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
            account_balance_after_transaction = array[-1].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
          else
            if (array[-2] =~ /^R\s-?[0-9\s]*.[0-9]{2}$/)
              amount = array[-2].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
              dep_id = array[-4] + array[-3]
            else
              dep_id = array[2]
              amount = array[-3].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
            end
            account_balance_after_transaction = array[-1].gsub("R", '').gsub(".", '').gsub(" ", '').to_i.to_s
          end

          if temp_date != array[0]
            count = 1
            temp_date = array[0]
          end

          results <<
              {
                :transaction_number_for_day => count,
                :account_number => account_number,
                :remittance_date => array[0],
                :description => array[1],
                :dep_id => dep_id,
                :amount => amount,
                :account_balance_after_transaction => account_balance_after_transaction
              }

          count += 1
        end

        button = agent.page.forms[0].button_with(:name => "button_buttonNext")

        agent.submit(agent.page.forms[0], agent.page.forms[0].button_with(:name => 'button_buttonNext')) unless button.nil?

      end
      # results.each {|x| puts x}
      results
    end
  end
end
