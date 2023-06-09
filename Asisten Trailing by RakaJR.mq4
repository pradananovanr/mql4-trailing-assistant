//+------------------------------------------------------------------+
//|                                                                  |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, PapaCoder"
#property link      "t.me/PrdnNvnRnt"
#property version   "1.00"
#property strict
#include  <stdlib.mqh>

enum trailMode {
   single = 0,//Single Order
   averaging = 1,//Averaging Order
};

extern string        _1                = "..::--====== Trailing Settings ======--::..";// 
input trailMode      TrailingMode      = single;//Trailing Mode
input double         TrailingStart     = 100;//Trailing Start in Point
input double         TrailingStop      = 10;//Trailing Stop in Point
extern string        break_1           = "";// 

extern string        _2                = "..::--====== Auxiliary ======--::..";// 
input int            MagicNumber       = 69696969;//Magic Number

int                  Slippage          = 3;//Slippage
string               EAComment         = "";//EA Comment

int digits, minstop;
double points, todayDD, DD;


//--------------------TEMPAT LOCK EA
string      lockNama         = "";              //Untuk Lock Nama (kosongkan jika tidak diperlukan)
int         lockAkun         = 0;               //Buat Lock Akun (isikan 0 jika tidak diperlukan)
datetime    expiryDate       = D'2999.12.12';   //Buat Lock Expiry Date Formatnya Tahun.Bulan.Tanggal (isikan 0 jika tidak diperlukan)


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

   digits       = (int)MarketInfo(Symbol(), MODE_DIGITS);
   points       =  SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   minstop     = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);

   papa.setPoint(points);
   papa.setMinstop(minstop);
   papa.setDigitPair(digits);
   papa.setOrderComment(EAComment);
   papa.setOrderMagic(MagicNumber);
   papa.setOrderSymbol(Symbol());
   papa.setSlippage(Slippage);
   papa.checkLock(lockNama, lockAkun, expiryDate);


//--- set Timer
   if(!IsTesting()) {
      int count = 0;
      bool timerSet = false;
      while(!timerSet && count < 5) {
         timerSet = EventSetTimer(2);
         if(!timerSet) {
            printf("Set Timer Error. Description %s. Trying %d...", ErrorDescription(_LastError), count);
            EventKillTimer();
            Sleep(200);
            timerSet = EventSetTimer(5);
            count++;
         }
      }
      if(!timerSet) {
         Alert("Cannot Set Timer. Please Re Init Your Experts");
         return INIT_FAILED;
      } else {
         printf("Set Timer at %s Success", Symbol());
      }
   }

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   EventKillTimer();
   if(!IsTesting()) {
      ObjectsDeleteAll();
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   papa.checkLock(lockNama, lockAkun, expiryDate);

   if(IsTesting()) {
      OnTimer();
   }
}
//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer() {
//---

   int countBuy = 0,
       countSell = 0,
       countBuyStop = 0,
       countSellStop = 0,
       countSellLimit = 0,
       countBuyLimit = 0,
       totalOP = 0;

   double lotBuy = 0,
          lastpriceBuy = 0,
          profitBuy = 0,
          SLBuy = 0,
          lotSell = 0,
          lastpriceSell = 0,
          profitSell = 0,
          SLSell = 0,
          lastlotBuy = 0,
          lastlotSell = 0,
          lastlotBuyLimit = 0,
          lastlotSellLimit = 0,
          lastlotBuyStop = 0,
          lastlotSellStop = 0,
          totalLotsBuy = 0,
          totalLotsSell = 0;

   RefreshRates();

   papa.orderInformation(countBuy, countSell, countBuyStop, countSellStop, countSellLimit, countBuyLimit, totalOP,
                         lotBuy, lastpriceBuy, profitBuy, SLBuy, lotSell, lastpriceSell, profitSell, SLSell, lastlotBuy, lastlotSell,
                         lastlotBuyLimit, lastlotSellLimit, lastlotBuyStop, lastlotSellStop, totalLotsBuy, totalLotsSell);

   int closedBuy = 0,
       closedSell = 0;
   double todayProfit = 0,
          weekProfit = 0;

   papa.orderHistoryInformation(closedBuy, closedSell, todayProfit, weekProfit);
   int totalClosed = closedBuy + closedSell;

   if(TrailingMode == single) {
      papa.singleTrailing(TrailingStart, TrailingStop);
   } else if(TrailingMode == averaging) {
      papa.trailingAveraging(TrailingStart, TrailingStop, papa.getBEP(OP_BUY), papa.getBEP(OP_SELL));
   }


}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long& lparam,
                  const double& dparam,
                  const string& sparam) {

   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "Close Buy") {
         int confirm = MessageBox("Are You Sure To Close All BUY Order(s)", "WARNING", MB_ICONWARNING | MB_OKCANCEL);

         if(confirm == IDOK) {
            Print("Close Buy Confirmed. Closing ...");
            papa.closeOrder(OP_BUY);
         }

         ObjectSetInteger(0, "Close Buy", OBJPROP_STATE, false);
      }

      if(sparam == "Close Sell") {
         int confirm = MessageBox("Are You Sure To Close All SELL Order(s)", "WARNING", MB_ICONWARNING | MB_OKCANCEL);

         if(confirm == IDOK) {
            Print("Close Sell Confirmed. Closing ...");
            papa.closeOrder(OP_SELL);
         }

         ObjectSetInteger(0, "Close Sell", OBJPROP_STATE, false);
      }

      if(sparam == "Close All Orders") {
         int confirm = MessageBox("Are You Sure To Close All Order(s)", "WARNING", MB_ICONWARNING | MB_OKCANCEL);

         if(confirm == IDOK) {
            Print("Close Buy and Sell Confirmed. Closing ...");
            papa.closeOrder(-1);
         }

         ObjectSetInteger(0, "Close All Orders", OBJPROP_STATE, false);
      }
   }
}







class PapaCoder {
 protected:
   double            point;
   int               minstop;
   int               magic;
   string            comment;
   int               digit;
   string            symbol;
   int               slippage;
 public:
//+------------------------------------------------------------------+
   void              setOrderMagic(const int oMagic) {
      magic = oMagic;
   }
//+------------------------------------------------------------------+
   void              setOrderComment(const string oComment) {
      comment = oComment;
   }
//+------------------------------------------------------------------+
   void              setDigitPair(const int Digit) {
      digit   = Digit;
   }
//+------------------------------------------------------------------+
   void              setOrderSymbol(const string oSymbol) {
      symbol  = oSymbol;
   }
//+------------------------------------------------------------------+
   void              setSlippage(const int slip) {
      slippage  = slip;
   }
//+------------------------------------------------------------------+
   void              setPoint(const double poin) {
      point  = poin;
   }
//+------------------------------------------------------------------+
   void              setMinstop(const int stop) {
      minstop  = stop;
   }
//+------------------------------------------------------------------+
   void              checkLock(string nama, int akun, datetime date) {

      if(nama != "") {
         papa.useLockNama(nama);
      }

      if(akun != 0) {
         papa.useLockAkun(akun);
      }

      if(date != 0) {
         papa.useExpiryDate(date);
      }

   }
//+------------------------------------------------------------------+
   double            symbolAsk() {
      return(SymbolInfoDouble(symbol, SYMBOL_ASK));
   }
//+------------------------------------------------------------------+
   double            symbolBid() {
      return(SymbolInfoDouble(symbol, SYMBOL_BID));
   }
//+------------------------------------------------------------------+
   void               sendBuy(double lot, double sl = 0, double tp = 0) {
      if(AccountFreeMarginCheck(symbol, OP_BUY, lot) > 0) {
         if(OrderSend(symbol, OP_BUY, lot, symbolAsk(), slippage, sl, tp, comment, magic, 0, clrBlue) <= 0) {
            Print("Order Send Buy Error. Lot : ", lot, " - SL : ", sl, " - TP : ", tp, ". Error Code : ", GetLastError(), " Description : ", ErrorDescription(GetLastError()));
         }
      }
   }
//+------------------------------------------------------------------+
   void               sendSell(double lot, double sl = 0, double tp = 0) {
      if(AccountFreeMarginCheck(symbol, OP_SELL, lot) > 0) {
         if(OrderSend(symbol, OP_SELL, lot, symbolBid(), slippage, sl, tp, comment, magic, 0, clrRed) <= 0) {
            Print("Order Send Sell Error. Lot : ", lot, " - SL : ", sl, " - TP : ", tp, ". Error Code : ", GetLastError(), " Description : ", ErrorDescription(GetLastError()));
         }
      }
   }
//+------------------------------------------------------------------+
   void               sendSellStop(double lot, double price, double sl = 0, double tp = 0, datetime expiry = 0) {
      if(AccountFreeMarginCheck(symbol, OP_SELL, lot) > 0) {
         if(symbolBid() - price >= minstop * point) {
            if(OrderSend(symbol, OP_SELLSTOP, lot, price, slippage, sl, tp, comment, magic, expiry, clrNONE) <= 0) {
               Print("Order Send SellStop Error. Lot : ", lot, " - Price : ", price, " - SL : ", sl, " - TP : ", tp, ". Error Code : ", GetLastError(), " Description : ", ErrorDescription(GetLastError()));
            }
         }
      }
   }
//+------------------------------------------------------------------+
   void               sendBuyStop(double lot, double price, double sl = 0, double tp = 0, datetime expiry = 0) {
      if(AccountFreeMarginCheck(symbol, OP_BUY, lot) > 0) {
         if(price - symbolAsk() >= minstop * point) {
            if(OrderSend(symbol, OP_BUYSTOP, lot, price, slippage, sl, tp, comment, magic, expiry, clrNONE) <= 0) {
               Print("Order Send BuyStop Error. Lot : ", lot, " - Price : ", price, " - SL : ", sl, " - TP : ", tp, ". Error Code : ", GetLastError(), " Description : ", ErrorDescription(GetLastError()));
            }
         }
      }
   }
//+------------------------------------------------------------------+
   void               sendSellLimit(double lot, double price, double sl = 0, double tp = 0, datetime expiry = 0) {
      if(AccountFreeMarginCheck(symbol, OP_SELL, lot) > 0) {
         if(price - symbolBid() >= minstop * point) {
            if(OrderSend(symbol, OP_SELLLIMIT, lot, price, slippage, sl, tp, comment, magic, expiry, clrNONE) <= 0) {
               Print("Order Send SellLimit Error. Lot : ", lot, " - Price : ", price, " - SL : ", sl, " - TP : ", tp, ". Error Code : ", GetLastError(), " Description : ", ErrorDescription(GetLastError()));
            }
         }
      }
   }
//+------------------------------------------------------------------+
   void               sendBuyLimit(double lot, double price, double sl = 0, double tp = 0, datetime expiry = 0) {
      if(AccountFreeMarginCheck(symbol, OP_BUY, lot) > 0) {
         if(symbolAsk() - price >= minstop * point) {
            if(OrderSend(symbol, OP_BUYLIMIT, lot, price, slippage, sl, tp, comment, magic, expiry, clrNONE) <= 0) {
               Print("Order Send BuyLimit Error. Lot : ", lot, " - Price : ", price, " - SL : ", sl, " - TP : ", tp, ". Error Code : ", GetLastError(), " Description : ", ErrorDescription(GetLastError()));
            }
         }
      }
   }
//+------------------------------------------------------------------+
   void              orderInformation(
      int &countBuy,
      int &countSell,
      int &countBuyStop,
      int &countSellStop,
      int &countSellLimit,
      int &countBuyLimit,
      int &totalOP,
      double &lotBuy,
      double &lastpriceBuy,
      double &profitBuy,
      double &SLBuy,
      double &lotSell,
      double &lastpriceSell,
      double &profitSell,
      double &SLSell,
      double &lastlotBuy,
      double &lastlotSell,
      double &lastlotBuyLimit,
      double &lastlotSellLimit,
      double &lastlotBuyStop,
      double &lastlotSellStop,
      double &tLotsBuy,
      double &tLotsSell) {

      for(int i = 0; i < OrdersTotal(); i++) {
         if(OrderSelect(i, SELECT_BY_POS) == True)
            if(OrderSymbol() == symbol)
               if(OrderMagicNumber() == magic) {
                  if(OrderType() == OP_BUY) {
                     countBuy++;
                     profitBuy += OrderProfit() + OrderSwap() + OrderCommission();
                     if(lotBuy == 0)
                        lotBuy = OrderLots();
                     lastlotBuy = OrderLots();
                     lastpriceBuy = OrderOpenPrice();
                     SLBuy = OrderStopLoss();
                     tLotsBuy += OrderLots();
                  }
                  if(OrderType() == OP_SELL) {
                     countSell++;
                     profitSell += OrderProfit() + OrderSwap() + OrderCommission();
                     if(lotSell == 0)
                        lotSell = OrderLots();
                     lastlotSell = OrderLots();
                     lastpriceSell = OrderOpenPrice();
                     SLSell = OrderStopLoss();
                     tLotsSell += OrderLots();
                  }

                  if(OrderType() == OP_BUYLIMIT) {
                     countBuyLimit++;
                     lastlotBuyLimit = OrderLots();
                  }

                  if(OrderType() == OP_SELLLIMIT) {
                     countSellLimit++;
                     lastlotSellLimit = OrderLots();
                  }

                  if(OrderType() == OP_BUYSTOP) {
                     countBuyStop++;
                     lastlotBuyStop = OrderLots();
                  }

                  if(OrderType() == OP_SELLSTOP) {
                     countSellStop++;
                     lastlotSellStop = OrderLots();
                  }
               }
      }
      totalOP = countBuy + countSell;
   }
//+------------------------------------------------------------------+
   double            getBEP(int type) {

      double tLots = 0;
      double tPrice = 0;
      double BEPrice = 0;
      for(int i = 0; i < OrdersTotal(); i++) {
         if(!OrderSelect(i, SELECT_BY_POS)) continue;
         if(OrderSymbol() == symbol &&
               OrderMagicNumber() == magic &&
               OrderType() == type) {
            tLots += OrderLots();
            tPrice += OrderOpenPrice() * OrderLots();
         }
      }

      if(tLots != 0) {
         BEPrice = NormalizeDouble(tPrice / tLots, digit);
      }
      return(BEPrice);
   }
//+------------------------------------------------------------------+
   bool              newCandle() {
      bool isNewCS = false;
      static datetime opTime  = TimeCurrent();
      if (iTime(Symbol(), 0, 0) > opTime) {
         opTime = iTime(Symbol(), 0, 0);
         isNewCS = true;
      }
      return (isNewCS);
   }
//+------------------------------------------------------------------+
   void orderHistoryInformation (
      int &closedBuy,
      int &closedSell,
      double &todayProfit,
      double &weeklyProfit) {

      double profitClosed = 0;
      double weekProfit = 0;

      for(int i = OrdersHistoryTotal() - 1; i >= 0; i--) {
         if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
            if(OrderSymbol() == symbol)
               if(OrderMagicNumber() == magic)
                  if(OrderType() < OP_BUYLIMIT) {
                     if(OrderCloseTime() >= iTime(symbol, PERIOD_D1, 0)) {
                        if(OrderType() == OP_BUY)
                           closedBuy++;
                        if(OrderType() == OP_SELL)
                           closedSell++;
                        profitClosed += OrderProfit() + OrderSwap() + OrderCommission();
                     }
                     if(OrderCloseTime() >= iTime(symbol, PERIOD_W1, 0)) {
                        weeklyProfit += OrderProfit() + OrderSwap() + OrderCommission();
                     }
                  }
         }
      }
      todayProfit = profitClosed;
   }
//-------------------------------------------------------------------+
   bool              buttonCreate(const string            name,
                                  const long                y) {
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, 110);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, 40);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrDarkOrange);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrDeepSkyBlue);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, name, OBJPROP_TEXT, name);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y * 45);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
      return(true);
   }
//+------------------------------------------------------------------+
   void              changeChart() {
      ChartSetInteger(0, CHART_SHOW_GRID, 0, false);
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, 0, true);
      ObjectsDeleteAll(0, -1, OBJ_LABEL);
      ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
      ChartSetInteger(0, CHART_SHIFT, true);
      ChartSetDouble(0, CHART_SHIFT_SIZE, 40);
      ChartSetInteger(0, CHART_SCALE, 3);
      ChartSetInteger(0, CHART_SHOW_ASK_LINE, true);
      ChartSetInteger(0, CHART_SHOW_BID_LINE, true);
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, C'36,36,36');
      ChartSetInteger(0, CHART_COLOR_BID, clrWheat);
      ChartSetInteger(0, CHART_COLOR_ASK, clrDarkOrange);
      ChartSetInteger(0, CHART_COLOR_CHART_UP, clrWhite);
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrDeepSkyBlue);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrWhite);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrDeepSkyBlue);
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrDeepSkyBlue);
      ChartSetInteger(0, CHART_COLOR_VOLUME, clrWhite);
   }
//+------------------------------------------------------------------+
   bool              jamTrading(int hourStart, int hourStop) {
      bool jtrade = false;
      MqlDateTime dt;
      TimeCurrent(dt);

      if(hourStart > hourStop) {
         if(dt.hour >= hourStart || dt.hour < hourStop)
            jtrade = true;
      } else if(dt.hour >= hourStart && dt.hour < hourStop)
         jtrade = true;
      return (jtrade);
   }
//+------------------------------------------------------------------+
   double            lotOptimized(int countOrder, double lotAwal, double multiplyLot) {
      double
      LotsMinimum = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN),
      LotsMaximum = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX),
      LotsStep    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

      double
      Multiply = multiplyLot,
      LotsInit = lotAwal;

      if(LotsInit < LotsMinimum) {
         LotsInit = LotsMinimum;
      }

      double
      NextMultiply  = LotsInit * pow(Multiply, countOrder);

      double
      LotsNext = fmin(LotsMaximum, fmax(LotsMinimum, round(NextMultiply / LotsStep) * LotsStep));
      return(LotsNext);
   }
//+------------------------------------------------------------------+
   void              tradeInfoDisplay(
      int      totalOP,
      int      countBuy,
      int      countSell,
      int      closedBuy,
      int      closedSell,
      double   totalLotBuy,
      double   totalLotSell,
      double   todayProfit,
      double   weekProfit,
      double   drawDown,
      double   todayDrawdown) {

      MqlDateTime dt;
      TimeCurrent(dt);

      string fill[38];

      fill[0] = "\n";
      fill[1] = ": " + (string)dt.year + " . " + (string)dt.mon + " . " + (string)dt.day;
      fill[2] = ": " + (string)dt.hour + " : " + (string)dt.min + " : " + (string)dt.sec;
      fill[3] = ": " + IntegerToString(MagicNumber);
      fill[4] = "";
      fill[5] = "";
      fill[6] = "";
      fill[7] = ": " + AccountInfoString(ACCOUNT_CURRENCY);
      fill[8] = ": " + AccountInfoString(ACCOUNT_NAME);
      fill[9] = ": " + (string)AccountInfoInteger(ACCOUNT_LOGIN);
      fill[10] = ": " + AccountInfoString(ACCOUNT_COMPANY);
      fill[11] = ": " + AccountInfoString(ACCOUNT_SERVER);
      fill[12] = ": 1 : " + (string)AccountInfoInteger(ACCOUNT_LEVERAGE);
      fill[13] = "";
      fill[14] = ": " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2);
      fill[15] = ": " + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2);
      fill[16] = ": " + DoubleToString(AccountInfoDouble(ACCOUNT_CREDIT), 2);
      fill[17] = "";
      fill[18] = "";
      fill[19] = "";
      fill[20] = ": " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 2);
      fill[21] = ": " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2);
      fill[22] = "";
      fill[23] = "";
      fill[24] = "";
      fill[25] = ": " + (string)totalOP + "  ||  " + (string)countBuy + " Buy" + " --- " + (string)countSell + " Sell";
      fill[26] = ": " + DoubleToString(totalLotBuy, 2);
      fill[27] = ": " + DoubleToString(totalLotSell, 2);
      fill[28] = "";
      fill[29] = "";
      fill[30] = "";
      fill[31] = ": " + (string)closedBuy;
      fill[32] = ": " + (string)closedSell;
      fill[33] = ": " + DoubleToString(todayProfit, 2);
      fill[34] = ": " + DoubleToString(weekProfit, 2);
      fill[35] = ": " + DoubleToString(drawDown, 2);
      fill[36] = ": " + DoubleToString(todayDrawdown, 2);
      fill[37] = ": " + (string)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);

      string info[38];
      info[0] = "\n";
      info[1] = "Date ";
      info[2] = "Time ";
      info[3] = "Expert Magic ";
      info[4] = "==============================";
      info[5] = "            ACCOUNT INFORMATION            ";
      info[6] = "==============================";
      info[7] = "Account Currency ";
      info[8] = "Account Name ";
      info[9] = "Account Number ";
      info[10] = "Account Broker ";
      info[11] = "Account Server ";
      info[12] = "Account Leverage ";
      info[13] = " ";
      info[14] = "Account Balance ";
      info[15] = "Account Equity ";
      info[16] = "Account Credit ";
      info[17] = "==============================";
      info[18] = "            MARGIN INFORMATION            ";
      info[19] = "==============================";
      info[20] = "Used Margin ";
      info[21] = "Free Margin ";
      info[22] = "==============================";
      info[23] = "            TRADE INFORMATION            ";
      info[24] = "==============================";
      info[25] = "Positions ";
      info[26] = "Total Lot Buy ";
      info[27] = "Total Lot Sell ";
      info[28] = "==============================";
      info[29] = "            HISTORY INFORMATION            ";
      info[30] = "==============================";
      info[31] = "Closed Buy ";
      info[32] = "Closed Sell ";
      info[33] = "Today Profit ";
      info[34] = "Week Profit ";
      info[35] = "Max Drawdown ";
      info[36] = "Today Drawdown ";
      info[37] = "Spread ";

      for(int i = 0; i < ArraySize(info); i++) {
         ObjectCreate(0, IntegerToString(i), OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, IntegerToString(i), OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetInteger(0, IntegerToString(i), OBJPROP_XDISTANCE, 270);
         ObjectSetInteger(0, IntegerToString(i), OBJPROP_YDISTANCE, 20 + (i * 14));
         ObjectSetInteger(0, IntegerToString(i), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
         ObjectSetString(0, IntegerToString(i), OBJPROP_TEXT, info[i]);
         ObjectSetInteger(0, IntegerToString(i), OBJPROP_COLOR, clrOrange);

         ObjectCreate(0, "Fill " + IntegerToString(i), OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, "Fill " + IntegerToString(i), OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetInteger(0, "Fill " + IntegerToString(i), OBJPROP_XDISTANCE, 160);
         ObjectSetInteger(0, "Fill " + IntegerToString(i), OBJPROP_YDISTANCE, 20 + (i * 14));
         ObjectSetInteger(0, "Fill " + IntegerToString(i), OBJPROP_CORNER, CORNER_RIGHT_UPPER);
         ObjectSetString(0, "Fill " + IntegerToString(i), OBJPROP_TEXT, fill[i]);
         ObjectSetInteger(0, "Fill " + IntegerToString(i), OBJPROP_COLOR, clrOrange);
      }
   }
//+------------------------------------------------------------------+
   void              closeOrder(ENUM_ORDER_TYPE Type) {
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         bool result = false;
         if(OrderSelect(i, SELECT_BY_POS) == True)
            if(OrderSymbol() == symbol &&
                  OrderMagicNumber() == magic) {
               if((OrderType() == Type || Type == -1) && OrderType() < OP_BUYLIMIT) {
                  if(!(OrderClose(OrderTicket(), OrderLots(), ((OrderType() == OP_SELL) ? symbolAsk() : symbolBid()), 3, clrWhite))) {
                     Print("Closing Order Failed. Error : ", ErrorDescription(GetLastError()));
                  }
               }
            }
      }
   }
//+------------------------------------------------------------------+
   void              deleteOrder(ENUM_ORDER_TYPE Type) {
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         if(OrderSelect(i, SELECT_BY_POS) == True)
            if(OrderSymbol() == symbol &&
                  OrderMagicNumber() == magic) {
               if(OrderType() == Type && OrderType() > OP_SELL) {
                  if(!OrderDelete(OrderTicket(), clrWhite)) {
                     Print("Deleting Order Failed. Error : ", ErrorDescription(GetLastError()));
                  }
               }
            }
      }
   }
//+------------------------------------------------------------------+
   void              modifyOrder(int Type, double SL, double TP) {
      for(int i = 0; i < OrdersTotal(); i++) {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
            break;
         if(OrderSymbol() != symbol)
            continue;
         if(OrderMagicNumber() == magic)
            if(OrderType() == Type)
               if(NormalizeDouble(OrderTakeProfit(), digit) != NormalizeDouble(TP, digit) || NormalizeDouble(OrderStopLoss(), digit) != NormalizeDouble(SL, digit))
                  bool result = OrderModify(OrderTicket(), OrderOpenPrice(), SL, TP, 0, clrNONE);
      }
   }
//+------------------------------------------------------------------+
   void              useLockNama(string namaAkun) {
      string accname = AccountInfoString(ACCOUNT_NAME);

      if(StringToUpper(accname) && StringToUpper(namaAkun)) {
         if(StringFind(accname, namaAkun, 0) < 0) {
            string pesanLockNama = StringFormat("This EA Not Registered For You, Your Account : %s. This EA Belongs To : %s",
                                                accname,
                                                namaAkun);
            Alert(pesanLockNama);
            ExpertRemove();
         }
      }
   }
//+------------------------------------------------------------------+
   void              useLockAkun(int nomorAkun) {
      if(AccountInfoInteger(ACCOUNT_LOGIN) != nomorAkun) {
         string pesanLockAkun = StringFormat("This EA Not Registered For You, Your Account : %s. This EA Belongs To Account : %s",
                                             (string)AccountInfoInteger(ACCOUNT_LOGIN),
                                             (string)nomorAkun);
         Alert(pesanLockAkun, nomorAkun);
         ExpertRemove();
      }
   }
//+------------------------------------------------------------------+
   void              useExpiryDate(datetime tglExpired) {
      string pesanExpiryDate = "This EA Expired";
      if((TimeLocal() > tglExpired || TimeCurrent() > tglExpired)) {
         Alert(pesanExpiryDate);
         ExpertRemove();
      }
   }
//+------------------------------------------------------------------+
   void              trailingAveraging(double tStart, double tStop, double pricebuy, double pricesell) {
      double Act;
      double SL;
      double Next;
      double TStart  = tStart + minstop;
      double BEPBuy  = pricebuy;
      double BEPSell = pricesell;

      if(tStop == 0) return;
      for(int i = OrdersTotal() - 1 ; i >= 0 ; i = i - 1) {
         if(!(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) || OrderSymbol() != symbol)   continue;
         if(OrderSymbol() == symbol) {
            if(OrderMagicNumber() == magic) {
               if(OrderType() == OP_BUY) {
                  if(BEPBuy != 0) {
                     Act = NormalizeDouble((papa.symbolBid() - BEPBuy) / point, 0);
                     if(Act < TStart) continue;
                     SL = OrderStopLoss();
                     Next = NormalizeDouble((papa.symbolBid() - (tStop * point)), digit);
                     if((SL == 0.0 || (SL != 0.0 && Next > SL)) && Next != SL) {
                        bool result = OrderModify(OrderTicket(), BEPBuy, Next, OrderTakeProfit(), 0, Aqua);
                     }
                  }
               }

               if(OrderType() == OP_SELL) {
                  if(BEPSell != 0) {
                     Act = NormalizeDouble((BEPSell - papa.symbolAsk()) / point, 0);
                     if(Act < TStart) continue;
                     SL = OrderStopLoss();
                     Next = NormalizeDouble(((tStop * point) + papa.symbolAsk()), digit);
                     if((SL == 0.0 || (SL != 0.0 && Next < SL)) && Next != SL) {
                        bool result = OrderModify(OrderTicket(), BEPSell, Next, OrderTakeProfit(), 0, Red) ;
                     }
                  }
               }
            }
         }
      }
   }
//+------------------------------------------------------------------+
   void              singleTrailing(double tStart, double tStop) {

      double SL      = (OrderStopLoss() != 0) ? OrderStopLoss() : OrderOpenPrice();
      double TSL     = 0;
      double Poin    = tStart + minstop;

      if(Poin == 0) return;
      for(int i = 0; i < OrdersTotal(); i++) {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
            if(OrderType() == OP_BUY &&
                  OrderSymbol() == symbol &&
                  OrderMagicNumber() == magic)
               if(papa.symbolBid() - OrderOpenPrice() >= Poin * point) {
                  if(SL < OrderOpenPrice())
                     SL = OrderOpenPrice();
                  if((papa.symbolBid() - SL) >= Poin * point) {
                     TSL = NormalizeDouble(papa.symbolBid() - ((Poin - tStop) * point), digit);
                  }
                  if(TSL > 0 && (OrderStopLoss() == 0 || (OrderStopLoss() != 0 && TSL > OrderStopLoss()))) {
                     bool result = OrderModify(OrderTicket(), OrderOpenPrice(), TSL, OrderTakeProfit(), 0, Red);
                  }
               }

         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
            if(OrderType() == OP_SELL &&
                  OrderSymbol() == symbol &&
                  OrderMagicNumber() == magic)
               if(OrderOpenPrice() - papa.symbolAsk() >= Poin * point) {
                  if(SL > OrderOpenPrice())
                     SL = OrderOpenPrice();
                  if((SL - papa.symbolAsk()) >= Poin * point) {
                     TSL = NormalizeDouble(papa.symbolAsk() + ((Poin - tStop) * point), digit);
                  }
                  if(TSL > 0 && (OrderStopLoss() == 0 || (OrderStopLoss() != 0 && TSL < OrderStopLoss()))) {
                     bool result = OrderModify(OrderTicket(), OrderOpenPrice(), TSL, OrderTakeProfit(), 0, Red);
                  }
               }
      }
   }
//+------------------------------------------------------------------+
   void              moveToBE(double moveAfter, double fromOpenPrice) {

      double Poin    = moveAfter + minstop;

      if(Poin == 0) return;
      for(int i = 0; i < OrdersTotal(); i++) {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
            if(OrderType() == OP_BUY &&
                  OrderSymbol() == symbol &&
                  OrderMagicNumber() == magic)
               if(papa.symbolBid() - OrderOpenPrice() >= Poin * point) {
                  if(OrderStopLoss() == 0 || OrderStopLoss() < OrderOpenPrice()) {
                     bool result = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + (fromOpenPrice * point), OrderTakeProfit(), 0, Red);
                  }
               }

         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
            if(OrderType() == OP_SELL &&
                  OrderSymbol() == symbol &&
                  OrderMagicNumber() == magic)
               if(OrderOpenPrice() - papa.symbolAsk() >= Poin * point) {
                  if(OrderStopLoss() == 0 || OrderStopLoss() > OrderOpenPrice()) {
                     bool result = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - (fromOpenPrice * point), OrderTakeProfit(), 0, Red);
                  }
               }
      }
   }
};
PapaCoder         papa;
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
